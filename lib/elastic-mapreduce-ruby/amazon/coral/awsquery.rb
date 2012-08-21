#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'uri'
require 'amazon/coral/identityhandler'
require 'amazon/coral/httpdestinationhandler'
require 'amazon/coral/awsqueryhandler'
require 'amazon/coral/v0signaturehandler'
require 'amazon/coral/v1signaturehandler'
require 'amazon/coral/v2signaturehandler'
require 'amazon/coral/awsqueryurihandler'
require 'amazon/coral/httphandler'
require 'amazon/coral/orchestrator'

module Amazon
  module Coral
    
    class AwsQuery
      
      @@identity_arg_keys = [:aws_access_key, :aws_secret_key, :http_authorization, :http_client_x509_cert, :http_client_x509_key]
      @@recognized_arg_keys = [:endpoint, :uri, :signature_algorithm, :ca_file, :verbose, 
                               :aws_access_key, :aws_secret_key, :http_authorization, :http_client_x509_cert, :http_client_x509_key,
                               :timeout, :connect_timeout]
      
      # Creates an Orchestrator capable of processing AWS/QUERY requests.  Possible arguments include:
      # [:endpoint]
      #   The HTTP URL at which the service is located.
      # [:signature_algorithm]
      #   The AWS signature version to be used to sign outgoing requests.  Current choices are:
      #     :V0 :V1 :V2
      #   By default, the version 2 signing algorithm is used.
      #   All signing may be disabled by passing the value 'nil' as the signature algorithm.
      # [:aws_access_key]
      #   An AWS access key to associate with every outgoing request.
      #   This parameter is optional and may be specified on a per-request basis as well.
      # [:aws_secret_key]
      #   An AWS secret key to associate with every outgoing request.
      #   This parameter is optional and may be specified on a per-request basis as well.
      # [:http_client_x509_cert]
      #   A base64-encoded X509 certificate to sign outgoing requests.
      #   Requires that the x509 key also be specified.
      # [:http_client_x509_key]
      #   A base64-encoded private key for an X509 certificate to sign outgoing requests.
      #   Requires that the x509 certificate also be specified.
      # [:http_authorization]
      #   The content of an http-authorization header to send with the request.
      #   Used for services which require HTTP basic authentication.
      # [:ca_file]
      #   A Certificate Authority file to pass to the HttpHandler.
      # [:timeout]
      #   The socket read timeout to use during service calls (see HttpHandler for details)
      # [:connect_timeout]
      #   A timeout to use for establishing a connection to the service (see HttpHandler for details)
      # [:verbose]
      #   A verbosity flag to pass to the HttpHandler.
      #
      # Example usage:
      #   orchestrator = AwsQuery.new_orchestrator(:endpoint => "http://localhost:8000", :signature_algorithm => :V2)
      #   client = ExampleClient.new(orchestrator)
      def AwsQuery.new_orchestrator(args)
        check_args(args)
        return Orchestrator.new(new_chain(args))
      end

      private
      def AwsQuery.new_chain(args)
        # remap args, add defaults where necessary:
        
        # support deprecated :uri mechanism of specifying service endpoint
        args[:endpoint] = args[:uri] if args[:endpoint].nil?
        
        # default to V2 if no algorithm is specified
        args[:signature_algorithm] = :V2 if args[:signature_algorithm].nil?
        
        # support the deprecated mechanism for specifying AWS account information
        args[:aws_access_key] = args[:access_key] if !args.has_key?(:aws_access_key) && args.has_key?(:access_key)
        args[:aws_secret_key] = args[:secret_key] if !args.has_key?(:aws_secret_key) && args.has_key?(:secret_key)
        
        
        
        # build up the chain:
        chain = []
        
        # allow user to preload identity attributes to be used on all requests
        identity_args = {}
        @@identity_arg_keys.each {|k|
          identity_args[k] = args[k] if args.has_key?(k)
        }
        chain << IdentityHandler.new(identity_args) unless identity_args.empty?
        
        # set the remote endpoint
        chain << HttpDestinationHandler.new(args[:endpoint])
        
        # use the AwsQuery protocol
        chain << AwsQueryHandler.new({:api_version => args[:api_version], :content_type => args[:content_type]})
        
        # select a signing algorithm
        case args[:signature_algorithm].to_sym
        when :V0
          chain << V0SignatureHandler.new
        when :V1
          chain << V1SignatureHandler.new
        when :V2
          chain << V2SignatureHandler.new
        end

        # collect the query string and update the destination URL
        chain << AwsQueryUriHandler.new

        # make connection over HTTP
        chain << HttpHandler.new( {:ca_file => args[:ca_file], :verbose => args[:verbose],
                                    :timeout => args[:timeout], :connect_timeout => args[:connect_timeout]} )

        return chain
      end

      def AwsQuery.check_args(args)
        log = LogFactory.getLog('Amazon::Coral::AwsQuery')

        args.each_key do |key|
          log.info("Unknown argument: #{key}") unless @@recognized_arg_keys.include?(key)
        end
      end

    end

  end
end
