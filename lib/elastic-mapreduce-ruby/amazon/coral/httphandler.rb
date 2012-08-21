#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'uri'
require 'net/http'
require 'net/https'
require 'amazon/coral/handler'
require 'amazon/coral/logfactory'

module Amazon
  module Coral

    # Executes HTTP requests via the Net::HTTP library.  Supports HTTP,
    # HTTPS and client X509 certificates.
    class HttpHandler < Handler
      
      # Instantiate a new HttpHandler with the specified arguments.  Possible arguments include:
      # [:verbose]
      #   If true, the handler will output the URI it is requesting to STDOUT.
      #   This may be useful for debugging purposes.
      # [:ca_file]
      #   This parameter's value points to a valid .pem certificate file to enable the 
      #   client to validate server certificates when using SSL.
      #   If this parameter is not specified, the client operates in insecure mode and does not
      #   validate that server certificates come from a trusted source.
      # [:timeout]
      #   This value (in seconds) will be used for every socket operation during the request.
      #   Note that since a request can involve many socket operations, calls that timeout may 
      #   actually take more time than this value.  If unspecified, defaults to 5.0 seconds.  
      #   A value of zero will result in an infinite timeout.
      # [:connect_timeout]
      #   This value (in seconds) will be used as the timeout for opening a connection to the 
      #   service.  If unspecified, defaults to 5.0 seconds.  A value of zero will result in
      #   an infinite timeout.
      def initialize(args = {})
        @log = LogFactory.getLog('Amazon::Coral::HttpHandler')

        @verbose = args[:verbose]
        @ca_file = args[:ca_file]
        @connect_timeout = args[:connect_timeout]
        @timeout = args[:timeout]

        @connect_timeout = 5.0 if @connect_timeout.nil?
        @timeout = 120.0 if @timeout.nil?

        raise ArgumentError, "connect_timeout must be non-negative" if @connect_timeout < 0
        raise ArgumentError, "timeout must be non-negative" if @timeout < 0
      end

      def before(job)
        identity = job.request[:identity]
        request_id = job.request[:id]
        uri = job.request[:http_uri]
        verb = job.request[:http_verb]
        query_map = job.request[:http_query_map]

        verb = 'GET' if verb.nil?

        headers = {}
        headers['x-amzn-RequestId'] = "#{request_id}"
        headers['x-amzn-Delegation'] = identity[:http_delegation] unless identity[:http_delegation].nil?
        headers['Authorization'] = identity[:http_authorization] unless identity[:http_authorization].nil?
        headers['Host'] = job.request[:http_host] unless job.request[:http_host].nil?
        headers['User-Agent'] = 'ruby-client'
        
        result = http_request(uri, headers, verb, query_map, identity[:http_client_x509], identity[:http_client_x509_key])

        @log.info "Response code: #{result.code}"

        job.reply[:response] = result
        job.reply[:value] = result.body
        job.reply[:http_status_code] = result.code
        job.reply[:http_status_message] = result.message
        job.reply[:http_content] = nil # TODO: get content-type header
      end

      private
      def http_request(uri, headers, verb, query_map = nil, cert = nil, key = nil)
        if @verbose then
          puts "Requesting URL:\n#{uri}\nQuery string:\n#{query_map}\nHeaders:\n#{headers}\n" 
        end

        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = @timeout;
        http.open_timeout = @connect_timeout;

        if(uri.scheme == 'https')
          # enable SSL
          http.use_ssl = true

          # if we haven't been given CA certificates to check, disable certificate verification (otherwise we'll get repeated warnings to STDOUT)
          if @ca_file.nil?
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          else
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER
            http.ca_file = @ca_file
          end

          # negotiate with the client certificate, if one is present
          unless(cert.nil? || key.nil?)
            http.cert = OpenSSL::X509::Certificate.new(cert)
            http.key = OpenSSL::PKey::RSA.new(key)
          end
        end

        if verb == 'GET'
          request = Net::HTTP::Get.new("#{uri.path}?#{uri.query}", headers)
        elsif verb == 'POST'
          request = Net::HTTP::Post.new("#{uri.path}?#{uri.query}", headers)
          request.set_form_data(query_map)
        else
          raise "Unrecognized http_verb: #{http_verb}"
        end

        http.start { |http|
          http.request(request)
        }

      end

    end

  end
end
