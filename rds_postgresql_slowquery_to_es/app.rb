# frozen_string_literal: true

require 'base64'
require 'digest/sha1'
require 'json'
require 'logger'
require 'open3'
require 'stringio'
require 'strscan'
require 'time'
require 'zlib'

require 'elasticsearch'

require File.expand_path('pg_logs', __dir__)
require File.expand_path('pg_slow_queries', __dir__)

PT_FINGERPRINT_PATH = File.join(__dir__, 'pt-fingerprint')
ELASTICSEARCH_URL = ENV.fetch('ELASTICSEARCH_URL')
LOGGER = Logger.new($stderr)

def decode_log(log:)
  data = log.fetch('awslogs').fetch('data')
  data_io = StringIO.new(Base64.decode64(data))
  json_str = Zlib::GzipReader.wrap(data_io, &:read)
  JSON.parse(json_str)
end

def pt_fingerprint(sql:)
  out, err, status = Open3.capture3(PT_FINGERPRINT_PATH, stdin_data: sql)
  raise "pt-fingerprint failed: stdout=#{out} stderr=#{err}" unless status.success?

  out
end

def fingerprint(sql:)
  sql_hash = Digest::SHA1.hexdigest(sql)
  fingerprint = pt_fingerprint(sql: sql)
  fingerprint.strip!
  fingerprint_hash = Digest::SHA1.hexdigest(fingerprint)

  {
    'sql' => sql, # Note: SQL may contain sensitive information
    'sql_fingerprint' => fingerprint,
    'sql_hash' => sql_hash,
    'sql_fingerprint_hash' => fingerprint_hash
  }
end

def parse_slowqueries(log_event:, log_group:, log_stream:, log_timestamp:, identifier:)
  message = log_event.fetch('message')
  pg_sqs = PGSlowQueries.new(message, logger: LOGGER)
  pg_sqs.parse!

  pg_sqs.slowqueries.map do |row|
    row = row.merge(
      'log_group' => log_group,
      'log_stream' => log_stream,
      'identifier' => identifier,
      'log_timestamp' => log_timestamp,
      'timestamp' => row.fetch('timestamp').iso8601
    )

    row.merge(fingerprint(sql: row.delete('statement')))
  end
end

def build_elasticsearch_client
  Elasticsearch::Client.new(url: ELASTICSEARCH_URL)
end

def post_to_elasticsearch(client:, docs:, index_prefix:)
  index_name = format("#{index_prefix}-%<today>s", today: Time.now.strftime('%Y.%m.%d'))

  body = docs.map do |doc|
    { index: { _index: index_name, data: doc } }
  end

  res = client.bulk(body: body)
  raise res.inspect if res['errors'] == true

  res
end

def filter_row_for_logging(row)
  row.reject { |k, _| k == 'sql_fingerprint' }
end

def lambda_handler(event:, context:) # rubocop:disable Lint/UnusedMethodArgument
  LOGGER.info("Receive a event: #{event.to_s.slice(0, 64)}...")

  log = decode_log(log: event)

  log_group = log.fetch('logGroup')
  log_stream = log.fetch('logStream')
  log_events = log.fetch('logEvents')
  identifier = log_group.split('/').fetch(4)

  LOGGER.info('Parse slowqueries')

  all_rows = []

  log_events.each do |log_event|
    log_timestamp = log_event.fetch('timestamp')

    rows = parse_slowqueries(
      log_event: log_event,
      log_group: log_group,
      log_stream: log_stream,
      log_timestamp: log_timestamp,
      identifier: identifier
    )

    all_rows.concat(rows)
  end

  unless all_rows.empty?
    es = build_elasticsearch_client
    index_prefix = log_group.sub(%r{\A/}, '').tr('/', '_')

    LOGGER.info("Post slowqueries: #{all_rows.map { |r| filter_row_for_logging(r) }}")
    res = post_to_elasticsearch(client: es, docs: all_rows, index_prefix: index_prefix)
    LOGGER.info("Posted slowqueries to Elasticsearch: #{res}")
  end

  nil
end
