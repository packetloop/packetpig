#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'openssl'
require 'base64'
require 'time'
require 'amazon/coral/handler'
require 'amazon/coral/v2signaturehelper'
require 'amazon/coral/logfactory'

module Amazon
  module Coral
    class V2SignatureHandler < Handler

      def initialize
        @log = LogFactory.getLog('Amazon::Coral::V2SignatureHandler')
      end

      def before(job)
        request = job.request
        identity = request[:identity]
        aws_access_key = identity[:aws_access_key]
        aws_secret_key = identity[:aws_secret_key]

        query_string_map = request[:query_string_map]
        http_uri = request[:http_uri]
        uri = http_uri.path
        verb = request[:http_verb]

        host = "#{http_uri.host}"
        host << ":#{http_uri.port}" unless http_uri.port.nil?

        @log.debug("uri: #{uri} verb: #{verb} host: #{host}")

        return if aws_access_key.nil? || aws_secret_key.nil? || query_string_map.nil? || 
          uri.nil? || verb.nil? || host.nil?;

        V2SignatureHelper.new(aws_access_key, aws_secret_key).sign({
          :query_string_map => query_string_map, :uri => uri, :verb => verb, :host => host
        })
        
        request[:http_host] = host
      end
    end
  end
end
