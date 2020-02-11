# frozen_string_literal: true

require 'base64'
require 'json'
require 'stringio'
require 'time'
require 'yaml'
require 'zlib'

require 'elasticsearch'
require 'timecop'

RSpec.configure do |config|
  def load_env
    template = YAML.load_file(File.join(__dir__, '../template.yaml'))
    envs = template.dig('Resources', 'RdsPostgresqlSlowqueryToEsFunction', 'Properties', 'Environment', 'Variables')
    local_env = JSON.parse(File.read(File.expand_path('../local-env.json', __dir__)))
    envs.update(local_env.fetch('RdsPostgresqlSlowqueryToEsFunction'))

    envs.each do |name, value|
      ENV[name] = value
    end

    ENV['TZ'] = 'UTC'
  end

  config.before(:all) do
    load_env
    require File.join(__dir__, '../rds_postgresql_slowquery_to_es/app')
  end
end
