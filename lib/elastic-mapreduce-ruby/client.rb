#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'credentials'
require 'amazon/retry_delegator'
require 'amazon/coral/elasticmapreduceclient'

class EmrClient
  attr_accessor :commands, :logger, :options

  def initialize(commands, logger, client_class)
    @commands = commands
    @logger = logger
    @options = commands.global_options

    @config = {
      :endpoint            => @options[:endpoint] || "https://elasticmapreduce.amazonaws.com",
      :ca_file             => File.join(File.dirname(__FILE__), "cacert.pem"),
      :aws_access_key      => @options[:aws_access_id],
      :aws_secret_key      => @options[:aws_secret_key],
      :signature_algorithm => :V2,
      :content_type        => 'JSON',
      :verbose             => (@options[:verbose] != nil),
      :connect_timeout     => 60.0,
      :timeout             => 160.0
    }

    @client = Amazon::RetryDelegator.new(
      client_class.new_aws_query(@config),
      :retry_if => Proc.new { |*opts| self.is_retryable_error_response(*opts) }
    )
  end

  def is_retryable_error_response(response)
    if response == nil then
      false
    else
      ret = false
      if response['Error'] then 
        # note: 'Timeout' is not retryable because the operation might have completed just the connection timed out
        ret ||= ['InternalFailure', 'Throttling', 'ServiceUnavailable'].include?(response['Error']['Code'])
      end
      ret 
    end
  end

  def is_error_response(response)
    response != nil && response.key?('Error')
  end

  def raise_on_error(response)
    if is_error_response(response) then
      raise RuntimeError, response["Error"]["Message"]
    end
    return response
  end

  def describe_jobflow_with_id(jobflow_id)
    logger.trace "DescribeJobFlows('JobFlowIds' => [ #{jobflow_id} ])"
    result = @client.DescribeJobFlows('JobFlowIds' => [ jobflow_id ], 'DescriptionType' => 'EXTENDED')
    logger.trace result.inspect
    raise_on_error(result)
    if result == nil || result['JobFlows'].size() == 0 then
      raise RuntimeError, "Jobflow with id #{jobflow_id} not found"
    end
    return result['JobFlows'].first
  end

  def add_steps(jobflow_id, steps)
    logger.trace "AddJobFlowSteps('JobFlowId' => #{jobflow_id.inspect}, 'Steps' => #{steps.inspect})"
    result = @client.AddJobFlowSteps('JobFlowId' => jobflow_id, 'Steps' => steps)
    logger.trace result.inspect
    return raise_on_error(result)
  end

  def run_jobflow(jobflow)
    logger.trace "RunJobFlow(#{jobflow.inspect})"
    result = @client.RunJobFlow(jobflow)
    logger.trace result.inspect
    return raise_on_error(result)
  end

  def describe_jobflow(options)
    logger.trace "DescribeJobFlows(#{options.inspect})"
    result = @client.DescribeJobFlows(options.merge('DescriptionType' => 'EXTENDED'))
    logger.trace result.inspect
    return raise_on_error(result)
  end

  def set_termination_protection(jobflow_ids, protected)
    logger.trace "SetTerminationProtection('JobFlowIds' => #{jobflow_ids.inspect}, 'TerminationProtected' => #{protected})"
    result = @client.SetTerminationProtection('JobFlowIds' => jobflow_ids, 'TerminationProtected' => protected)
    logger.trace result.inspect
    return raise_on_error(result)
  end

  def terminate_jobflows(jobflow_ids)
    logger.trace "TerminateJobFlows('JobFlowIds' => #{jobflow_ids.inspect})"
    result = @client.TerminateJobFlows('JobFlowIds' => jobflow_ids)
    logger.trace result.inspect
    return raise_on_error(result)
  end

  def modify_instance_groups(options)
    logger.trace "ModifyInstanceGroups(#{options.inspect})"
    result = @client.ModifyInstanceGroups(options)
    logger.trace result.inspect
    return raise_on_error(result)
  end    

  def add_instance_groups(options)
    logger.trace "AddInstanceGroups(#{options.inspect})"
    result = @client.AddInstanceGroups(options)
    logger.trace result.inspect
    return raise_on_error(result)
  end    

end

