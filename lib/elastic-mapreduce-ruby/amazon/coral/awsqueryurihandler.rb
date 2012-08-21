#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'uri'
require 'amazon/coral/handler'
require 'amazon/coral/logfactory'

module Amazon
  module Coral

    # Compiles the request URL from AwsQueryHandler and any intervening
    # signature handler.
    class AwsQueryUriHandler < Handler
      def initialize
        @log = LogFactory.getLog('Amazon::Coral::AwsQueryUriHandler')
      end

      def before(job)
        http_verb = job.request[:http_verb]

        if http_verb.nil?
          raise "http_verb must be defined"
        elsif http_verb == 'GET' || http_verb == 'HEAD'
          job.request[:http_uri].query = job.request[:query_string_map].to_s
        else
          job.request[:http_query_map] = job.request[:query_string_map]
        end

        @log.debug "Final request URI: #{job.request[:http_uri]}"
      end
    end

  end
end
