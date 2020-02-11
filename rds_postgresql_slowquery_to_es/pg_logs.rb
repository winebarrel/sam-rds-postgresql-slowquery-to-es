# !/usr/bin/env ruby
# frozen_string_literal: true

require 'strscan'
require 'logger'
require 'time'

class PGLogs
  R_TIMESTAMP = /(.*?)(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [A-Z]+):/im.freeze

  attr_reader :rows

  def initialize(src, logger: Logger.new($stdout))
    @ss = StringScanner.new(src)
    @logger = logger
    @rows = []
  end

  def parse!
    prefix_fields = []

    while !@ss.eos? && @ss.scan(R_TIMESTAMP)
      log = @ss[1]
      ts = @ss[2]
      parse_row(log, ts, prefix_fields)
    end

    append_row(prefix_fields, @ss.rest) if @ss.rest?
    @rows.freeze
  end

  private

  def parse_row(log, timestamp, prefix_fields)
    append_row(prefix_fields, log) unless log.empty?
    prefix_fields << timestamp

    scan_host_port(prefix_fields) &&
      scan_user_db(prefix_fields) &&
      scan_pid(prefix_fields) &&
      scan_log_type(prefix_fields)
  end

  def append_row(prefix_fields, log)
    if prefix_fields.empty?
      @logger.warn("Missing prefix fields: #{log.inspect}")
    elsif prefix_fields.length != 5
      @logger.warn("Wrong number of prefix fields: prefix fields=#{prefix_fields} log=#{log.inspect}")
    else
      row = {
        'timestamp' => Time.parse(prefix_fields.fetch(0)),
        'log' => log
      }

      row.update(prefix_fields.fetch(1))
      row.update(prefix_fields.fetch(2))
      row.update(prefix_fields.fetch(3))
      row.update(prefix_fields.fetch(4))
      @rows << row
    end

    prefix_fields.clear
  end

  def scan_host_port(prefix_fields)
    unless @ss.scan(/(.*?):/)
      @logger.warn("Host and Port not found in log line: #{prefix_fields}")
      prefix_fields.clear
      return false
    end

    host_port = @ss[1]

    host_port = if host_port =~ /([^(]+)\((\d+)\)/
                  { 'host' => Regexp.last_match(1), 'port' => Regexp.last_match(2).to_i }
                else
                  { 'host' => host_port }
                end

    prefix_fields << host_port

    true
  end

  def scan_user_db(prefix_fields)
    unless @ss.scan(/(.*?):/)
      @logger.warn("User name and Database name not found in log line: #{prefix_fields}")
      prefix_fields.clear
      return false
    end

    user_db = @ss[1]

    user_db = if user_db =~ /([^@]+)@(.+)/
                { 'user' => Regexp.last_match(1), 'database' => Regexp.last_match(2) }
              else
                { 'user' => user_db }
              end

    prefix_fields << user_db

    true
  end

  def scan_pid(prefix_fields)
    unless @ss.scan(/(.*?):/)
      @logger.warn("User name and Database name not found in log line: #{prefix_fields}")
      prefix_fields.clear
      return false
    end

    pid = @ss[1]

    pid = if pid =~ /\[(\d+)\]/
            { 'pid' => Regexp.last_match(1).to_i }
          else
            { 'pid' => pid }
          end

    prefix_fields << pid

    true
  end

  def scan_log_type(prefix_fields)
    unless @ss.scan(/(.*?):/)
      @logger.warn("Log type not found in log line: #{prefix_fields}")
      prefix_fields.clear
      return false
    end

    log_type = @ss[1]
    prefix_fields << { 'log_type' => log_type }

    true
  end
end
