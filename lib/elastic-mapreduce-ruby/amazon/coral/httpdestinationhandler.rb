# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'uri'
require 'amazon/coral/handler'
require 'amazon/coral/logfactory'

module Amazon
  module Coral

    # Attaches the specified endpoint URI to the outgoing request.
    class HttpDestinationHandler < Handler

      # Initialize an HttpDestinationHandler with the specified endpoint
      # URI.
      def initialize(endpoint)
        @log = LogFactory.getLog('Amazon::Coral::HttpDestinationHandler')

        @uri = case endpoint
               when URI:
                   endpoint
               else
                 URI.parse(endpoint)
               end
        @uri.path = '/' if @uri.path.nil? || @uri.path.empty?
      end

      def before(job)
        job.request[:http_verb] = 'GET'
        job.request[:http_uri] = @uri.clone

        @log.debug "Initial request URI #{@uri}"
      end
    end

  end
end
