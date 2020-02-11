# frozen_string_literal: true

RSpec.describe '#lambda_handler' do
  let(:freeze_time) do
    Time.parse('2019/01/23 12:34:56 UTC')
  end

  let(:postgresql_log) do
    <<~SQL
      2019-01-23 12:34:56 UTC:10.0.1.188(53552):postgres@postgres:[19337]:LOG:  duration: 3006.667 ms  statement: select pg_sleep(1);
    SQL
  end

  let(:log_group) do
    '/aws/rds/cluster/my-cluster/postgresql'
  end

  let(:log_stream) do
    'my-instance'
  end

  let(:message) do
    {
      messageType: 'DATA_MESSAGE',
      owner: '822997939312',
      logGroup: log_group,
      logStream: log_stream,
      subscriptionFilters: [
        'LambdaStream_slowquery-to-es'
      ],
      logEvents: [
        {
          id: '34988627466400403128808512274575692581164466220493963264',
          timestamp: 1_568_944_318_000,
          message: postgresql_log
        }
      ]
    }
  end

  let(:event) do
    gzip = StringIO.new.yield_self do |buf|
      Zlib::GzipWriter.wrap(buf) do |gz|
        gz.write(message.to_json)
      end

      buf.string
    end

    {
      'awslogs' => {
        'data' => Base64.strict_encode64(gzip)
      }
    }
  end

  let(:elasticsearch_client) do
    Elasticsearch::Client.new
  end

  before do
    Timecop.freeze(freeze_time)
    allow(LOGGER).to receive(:info)
    allow(self).to receive(:build_elasticsearch_client).and_return(elasticsearch_client)
  end

  after do
    Timecop.return
  end

  context 'when receive a slowquery' do
    specify 'post to elasticsearch' do
      expect(elasticsearch_client).to receive(:bulk).with(
        body: [
          {
            index: {
              _index: 'aws_rds_cluster_my-cluster_postgresql-2019.01.23',
              data: {
                'database' => 'postgres',
                'duration' => 3006.667,
                'host' => '10.0.1.188',
                'identifier' => 'my-cluster',
                'log_group' => '/aws/rds/cluster/my-cluster/postgresql',
                'log_stream' => 'my-instance',
                'log_timestamp' => 1_568_944_318_000,
                'log_type' => 'LOG',
                'pid' => 19_337,
                'port' => 53_552,
                'sql' => 'select pg_sleep(1);',
                'sql_fingerprint' => 'select pg_sleep(?);',
                'sql_fingerprint_hash' => 'b916ebb1bc05de3d69d3ed98d3f1e34f72513240',
                'sql_hash' => '6a8f43773760128b07b76433a1ab216ca8cdedb1',
                'timestamp' => '2019-01-23T12:34:56Z',
                'user' => 'postgres'
              }
            }
          }
        ]
      ).and_return({})

      retval = lambda_handler(event: event, context: nil)
      expect(retval).to be_nil
    end
  end
end
