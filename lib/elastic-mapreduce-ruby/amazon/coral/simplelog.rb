#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'amazon/coral/logfactory'
require 'logger'

module Amazon
  module Coral

    # Wraps Ruby's built in Logger to prepend a context string to log messages.
    # This is useful to prefix log messages with the name of the originating class, etc.
    class WrappedLogger
      def initialize(key, logger)
        @key = key
        @logger = logger
      end

      def debug(s)
        @logger.debug(format(s))
      end
      def info(s)
        @logger.info(format(s))
      end
      def warn(s)
        @logger.warn(format(s))
      end
      def error(s)
        @logger.error(format(s))
      end
      def fatal(s)
        @logger.fatal(format(s))
      end

      def debug?
        @logger.debug?
      end
      def info?
        @logger.info?
      end
      def warn?
        @logger.warn?
      end
      def error?
        @logger.error?
      end
      def fatal?
        @logger.fatal?
      end

      def format(s)
        return "#{@key}: #{s}"
      end
    end

    #
    # Provides a LogFactory implementation that supplies WrappedLogger objects to requestors.
    # The key provided to getLog is prepended to log messages from each Logger.
    #
    # Copyright:: Copyright (c) 2008 Amazon.com, Inc. or its affiliates.  All Rights Reserved.
    #
    class SimpleLogFactory < LogFactory
      def initialize(output, level)
        @output = output
        @level = level
      end

      def getLog(key)
        logger = Logger.new(@output)
        logger.level = @level

        return WrappedLogger.new(key, logger)
      end
    end

    #
    # Provides a straightforward facility to configure SimpleLog as the active logging mechanism.
    #
    # Copyright:: Copyright (c) 2008 Amazon.com, Inc. or its affiliates.  All Rights Reserved.
    #
    class SimpleLog
      # Registers a SimpleLogFactory with the specified output IO object and logging level.
      #
      # To set logging to its highest level and send output to the console, use:
      #   SimpleLog.install(STDOUT, Logger:DEBUG)
      #
      # To send logging output to a file:
      #   SimpleLog.install(File.new('/tmp/simplelog.log', 'r'), Logger::INFO)
      #
      # Installing a new LogFactory will not affect objects that have already retrieved their log instances,
      # it's best to initialize logging as early as possible in your code to ensure that all your code gets
      # the proper configuration.
      def SimpleLog.install(output, level)
        LogFactory.setInstance(SimpleLogFactory.new(output, level))
      end
    end

  end
end
