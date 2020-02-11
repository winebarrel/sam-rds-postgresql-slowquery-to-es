#!/usr/bin/env ruby
# frozen_string_literal: true

require 'strscan'
require 'logger'
require 'time'

class PGSlowQueries
  attr_reader :slowqueries

  def initialize(src, logger: Logger.new($stdout))
    @pg_logs = PGLogs.new(src, logger: logger)
    @slowqueries = []
  end

  def parse!
    @pg_logs.parse!

    @pg_logs.rows.each do |row|
      row = row.dup
      log_type = row.fetch('log_type')
      log = row.delete('log')

      next unless log_type == 'LOG' && log =~ /\A\s*duration:\s+(\d+\.\d+)\s+ms\s+statement:\s+(.+)/m

      row = row.dup
      row.update(
        'duration' => Regexp.last_match(1).to_f,
        'statement' => Regexp.last_match(2).strip
      )
      @slowqueries << row
    end

    @slowqueries.freeze
  end
end
