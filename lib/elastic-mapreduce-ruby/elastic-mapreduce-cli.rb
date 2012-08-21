#!/usr/bin/env ruby
#
# Copyright 2008-2011 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'commands'
require 'simple_logger'
require 'simple_executor'

exit_code = 0
begin
  logger = SimpleLogger.new
  executor = SimpleExecutor.new
  commands = Commands::create_and_execute_commands(
    ARGV, Amazon::Coral::ElasticMapReduceClient, logger, executor
  )
rescue SystemExit => e
  exit_code = -1
rescue Exception => e
  STDERR.puts("Error: " + e.message)
  STDERR.puts(e.backtrace.join("\n"))
  exit_code = -1
end

exit(exit_code)
