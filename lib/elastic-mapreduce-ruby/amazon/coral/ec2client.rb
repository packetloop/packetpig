#
# Copyright 2008-2011 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'amazon/coral/dispatcher'
require 'amazon/coral/call'
require 'amazon/coral/service'

module Amazon
  module Coral

    # Client interface for calling Ec2.
    #
    # The client supports two mechanisms to invoke each remote service call: a simple approach
    # which directly calls the remote service, or a Call based mechanism that allows you to
    # control aspects of the outgoing request such as request-id and identity attributes.
    #
    # Each instance of a client interface is backed by an Orchestrator object which manages
    # the processing of each request to the remote service.
    # Clients can be instantiated with a custom orchestrator or with presets corresponding to
    # particular protocols.  Inputs and return values to the direct service-call methods and
    # the Call.call methods are hashes.
    class Ec2Client
      # Construct a new client.  Takes an orchestrator through which to process requests.
      # See additional constructors below to use pre-configured orchestrators for specific protocols.
      #
      # [orchestrator]
      #   The Orchestrator is responsible for actually making the remote service call.  Clients
      #   construct requests, hand them off to the orchestrator, and receive responses in return.
      def initialize(orchestrator)
        @allocateAddressDispatcher = Dispatcher.new(orchestrator, 'Ec2', 'AllocateAddress')
        @associateAddressDispatcher = Dispatcher.new(orchestrator, 'Ec2', 'AssociateAddress')
      end


      # Instantiates a call object to invoke the AllocateAddress operation:
      #
      # Example usage:
      #   my_call = my_client.newAllocateAddressCall
      #   # set identity information if needed
      #   my_call.identity[:aws_access_key] = my_access_key
      #   my_call.identity[:aws_secret_key] = my_secret_key
      #   # make the remote call
      #   my_call.call(my_input)
      #   # retrieve the request-id returned by the server
      #   my_request_id = my_call.request_id
      def newAllocateAddressCall
        Call.new(@allocateAddressDispatcher)
      end

      def newAssociateAddressCall
        Call.new(@associateAddressDispatcher)
      end


      # Shorthand method to invoke the AllocateAddress operation:
      #
      # Example usage:
      #   my_client.AllocateAddress(my_input)
      def AllocateAddress(input = {})
        newAllocateAddressCall.call(input)
      end
      
      # Shorthand method to invoke the AssociateAddress operation:
      #
      # Example usage:
      #   my_client.AssociateAddress(my_input)
      def AssociateAddress(input = {})
        newAssociateAddressCall.call(input)
      end

      #TODO: Add stubs for all other Ec2 WS operations here, see http://s3.amazonaws.com/ec2-downloads/2010-11-15.ec2.wsdl


      # Instantiates the client with an orchestrator configured for use with AWS/QUERY.
      # Use of this constructor is deprecated in favor of using the AwsQuery class:
      #   client = Ec2Client.new(AwsQuery.new_orchestrator(args))
      def Ec2Client.new_aws_query(args)
        require 'amazon/coral/awsquery'
        Ec2Client.new(AwsQuery.new_orchestrator(args))
      end

    end

    # allow running from the command line
    Service.new(:service => 'Ec2', :operations => [
                                                     'AllocateAddress',
                                                     'AssociateAddress'
                                                  ]).main if caller.empty?
  end
end

