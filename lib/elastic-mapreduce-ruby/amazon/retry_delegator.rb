#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'amazon/stderr_logger.rb'

module Amazon

  # RetryDelegator
  #   this is a wrapper around a client that will retry if exceptions are raised.
  class RetryDelegator
    def initialize(client, options={})
      @client            = client
      @log               = options[:log] || StdErrLogger.new
      @backoff_seconds   = options[:backoff_seconds] || 2
      @backoff_mult      = options[:backoff_mult] || 1.5
      @retries           = options[:retries] || 8
      @retry_if          = options[:retry_if]
      @pass_exceptions   = options[:pass_exceptions] || [ScriptError, SignalException, ArgumentError, StandardError]
      @retry_exceptions  = options[:retry_exceptions] || [IOError, EOFError, RuntimeError]
    end

    def is_retry_exception(e)
      if @retry_exceptions then
        for retry_exception in @retry_exceptions do
          return true if e.is_a?(retry_exception)
        end
      end
      if @pass_exceptions then
        for pass_exception in @pass_exceptions do
          return false if e.is_a?(pass_exception)
        end
        return true
      else
        return false
      end
    end

    def method_missing(method, *args)
      backoff_seconds = @backoff_seconds
      backoff_mult = @backoff_mult
      retries_remaining = @retries
      begin
        response = @client.send(method, *args)
        if @retry_if && @retry_if.call(response) then
          raise "Retriable invalid response returned from #{method}: #{response.inspect}"
        end
        return response
      rescue Exception => e
        if retries_remaining > 0 && is_retry_exception(e) then
          if @log != nil then
            @log.info "Exception #{e.to_str} while calling #{method} on #{@client.class}, retrying in #{@backoff_seconds * backoff_mult} seconds."
          end
          sleep(@backoff_seconds * backoff_mult)
          backoff_mult *= 2
          retries_remaining -= 1
          retry
        else
          if @log != nil then
            @log.info "Exception #{e.to_str} while calling #{method} on #{@client.class}, failing"
          end
          raise e
        end
      end
    end
  end
end
