#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'amazon/coral/dispatcher'
require 'amazon/coral/call'
require 'amazon/coral/service'

module Amazon
  module Coral

    # Client interface for calling ElasticMapReduce.
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
    class ElasticMapReduceClient
      # Construct a new client.  Takes an orchestrator through which to process requests.
      # See additional constructors below to use pre-configured orchestrators for specific protocols.
      #
      # [orchestrator]
      #   The Orchestrator is responsible for actually making the remote service call.  Clients
      #   construct requests, hand them off to the orchestrator, and receive responses in return.
      def initialize(orchestrator)
        @addJobFlowStepsDispatcher = Dispatcher.new(orchestrator, 'ElasticMapReduce', 'AddJobFlowSteps')
        @addInstanceGroupsDispatcher = Dispatcher.new(orchestrator, 'ElasticMapReduce', 'AddInstanceGroups')
        @terminateJobFlowsDispatcher = Dispatcher.new(orchestrator, 'ElasticMapReduce', 'TerminateJobFlows')
        @setTerminationProtectionDispatcher = Dispatcher.new(orchestrator, 'ElasticMapReduce', 'SetTerminationProtection')
        @describeJobFlowsDispatcher = Dispatcher.new(orchestrator, 'ElasticMapReduce', 'DescribeJobFlows')
        @runJobFlowDispatcher = Dispatcher.new(orchestrator, 'ElasticMapReduce', 'RunJobFlow')
        @modifyInstanceGroupsDispatcher = Dispatcher.new(orchestrator, 'ElasticMapReduce', 'ModifyInstanceGroups')
      end


      # Instantiates a call object to invoke the AddJobFlowSteps operation:
      #
      # Example usage:
      #   my_call = my_client.newAddJobFlowStepsCall
      #   # set identity information if needed
      #   my_call.identity[:aws_access_key] = my_access_key
      #   my_call.identity[:aws_secret_key] = my_secret_key
      #   # make the remote call
      #   my_call.call(my_input)
      #   # retrieve the request-id returned by the server
      #   my_request_id = my_call.request_id
      def newAddJobFlowStepsCall
        Call.new(@addJobFlowStepsDispatcher)
      end

      # Instantiates a call object to invoke the AddInstanceGroups operation:
      #
      # Example usage:
      #   my_call = my_client.newAddInstanceGroupsCall
      #   # set identity information if needed
      #   my_call.identity[:aws_access_key] = my_access_key
      #   my_call.identity[:aws_secret_key] = my_secret_key
      #   # make the remote call
      #   my_call.call(my_input)
      #   # retrieve the request-id returned by the server
      #   my_request_id = my_call.request_id
      def newAddInstanceGroupsCall
        Call.new(@addInstanceGroupsDispatcher)
      end

      # Instantiates a call object to invoke the TerminateJobFlows operation:
      #
      # Example usage:
      #   my_call = my_client.newTerminateJobFlowsCall
      #   # set identity information if needed
      #   my_call.identity[:aws_access_key] = my_access_key
      #   my_call.identity[:aws_secret_key] = my_secret_key
      #   # make the remote call
      #   my_call.call(my_input)
      #   # retrieve the request-id returned by the server
      #   my_request_id = my_call.request_id
      def newTerminateJobFlowsCall
        Call.new(@terminateJobFlowsDispatcher)
      end

      # Instantiates a call object to invoke the SetTerminationProtection operation:
      def newSetTerminationProtectionCall
        Call.new(@setTerminationProtectionDispatcher)
      end

      # Instantiates a call object to invoke the DescribeJobFlows operation:
      #
      # Example usage:
      #   my_call = my_client.newDescribeJobFlowsCall
      #   # set identity information if needed
      #   my_call.identity[:aws_access_key] = my_access_key
      #   my_call.identity[:aws_secret_key] = my_secret_key
      #   # make the remote call
      #   my_output = my_call.call(my_input)
      #   # retrieve the request-id returned by the server
      #   my_request_id = my_call.request_id
      def newDescribeJobFlowsCall
        Call.new(@describeJobFlowsDispatcher)
      end

      # Instantiates a call object to invoke the RunJobFlow operation:
      #
      # Example usage:
      #   my_call = my_client.newRunJobFlowCall
      #   # set identity information if needed
      #   my_call.identity[:aws_access_key] = my_access_key
      #   my_call.identity[:aws_secret_key] = my_secret_key
      #   # make the remote call
      #   my_output = my_call.call(my_input)
      #   # retrieve the request-id returned by the server
      #   my_request_id = my_call.request_id
      def newRunJobFlowCall
        Call.new(@runJobFlowDispatcher)
      end

      def newModifyInstanceGroupsCall
        Call.new(@modifyInstanceGroupsDispatcher)
      end


      # Shorthand method to invoke the AddJobFlowSteps operation:
      #
      # Example usage:
      #   my_client.AddJobFlowSteps(my_input)
      def AddJobFlowSteps(input = {})
        newAddJobFlowStepsCall.call(input)
      end
      
      # Shorthand method to invoke the AddInstanceGroups operation:
      #
      # Example usage:
      #   my_client.AddInstanceGroups(my_input)
      def AddInstanceGroups(input = {})
        newAddInstanceGroupsCall.call(input)
      end

      # Shorthand method to invoke the TerminateJobFlows operation:
      #
      # Example usage:
      #   my_client.TerminateJobFlows(my_input)
      def TerminateJobFlows(input = {})
        newTerminateJobFlowsCall.call(input)
      end

      # Shorthand method to invoke the SetTerminationProtection operation:
      def SetTerminationProtection(input = {})
        newSetTerminationProtectionCall.call(input)
      end

      # Shorthand method to invoke the DescribeJobFlows operation:
      #
      # Example usage:
      #   my_output = my_client.DescribeJobFlows(my_input)
      def DescribeJobFlows(input = {})
        newDescribeJobFlowsCall.call(input)
      end

      # Shorthand method to invoke the RunJobFlow operation:
      #
      # Example usage:
      #   my_output = my_client.RunJobFlow(my_input)
      def RunJobFlow(input = {})
        newRunJobFlowCall.call(input)
      end


      def ModifyInstanceGroups(input = {})
        newModifyInstanceGroupsCall.call(input)
      end


      # Instantiates the client with an orchestrator configured for use with AWS/QUERY.
      # Use of this constructor is deprecated in favor of using the AwsQuery class:
      #   client = ElasticMapReduceClient.new(AwsQuery.new_orchestrator(args))
      def ElasticMapReduceClient.new_aws_query(args)
        require 'amazon/coral/awsquery'
        ElasticMapReduceClient.new(AwsQuery.new_orchestrator(args))
      end

    end

    # allow running from the command line
    Service.new(:service => 'ElasticMapReduce', :operations => [
                                                                'AddJobFlowSteps',
                                                                'AddInstanceGroups',
                                                                'TerminateJobFlows',
                                                                'SetTerminationProtection',
                                                                'DescribeJobFlows',
                                                                'RunJobFlow',
                                                                'ModifyInstanceGroups'
                                                               ]).main if caller.empty?
  end
end

