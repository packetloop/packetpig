#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

class SimpleLogger
  attr_accessor :level

  def initialize
    @level = :info
  end

  def puts(msg)
    STDOUT.puts msg
  end

  def trace(msg)
    if [:debug, :trace].include?(level) then
      STDOUT.puts "#{Time.now.utc} TRACE " + msg
    end
  end

  def info(msg)
    if [:debug, :trace, :info].include?(level) then
      STDOUT.puts "#{Time.now.utc} INFO " + msg
    end
  end

  def error(msg)
    if [:debug, :trace, :info, :error].include?(level) then
      STDOUT.puts "#{Time.now.utc} ERROR " + msg
    end
  end

  def fatal(msg)
    if [:debug, :trace, :info, :error, :fatal].include?(level) then
      STDOUT.puts "#{Time.now.utc} FATAL " + msg
    end
  end
end
