#
# Copyright 2008-2011 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'credentials'
require 'amazon/retry_delegator'
require 'amazon/coral/ec2client'

class Ec2ClientWrapper
  attr_accessor :commands, :logger, :options

  def initialize(commands, logger)
    @commands = commands
    @logger = logger
    @options = commands.global_options

    @config = {
      :endpoint            => @options[:ec2_endpoint] || "https://ec2.amazonaws.com",
      :api_version         => '2010-11-15',
      :ca_file             => File.join(File.dirname(__FILE__), "cacert.pem"),
      :aws_access_key      => @options[:aws_access_id],
      :aws_secret_key      => @options[:aws_secret_key],
      :signature_algorithm => :V2,
      :verbose             => (@options[:verbose] != nil)
    }

    @client = Amazon::RetryDelegator.new(
      Amazon::Coral::Ec2Client.new_aws_query(@config),
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
        ret ||= ['Throttling', 'ServiceUnavailable'].include?(response['Error']['Code'])
      end
      ret 
    end
  end

  def is_error_response(response)
    response != nil && response.key?('Error')
  end

  def raise_on_error(response)
    if is_error_response(response) then
      raise RuntimeError, response["Error"].inspect
    end
    return response
  end

  def allocate_address()
    logger.trace "AllocateAddress()"
    result = @client.AllocateAddress()
    logger.trace result.inspect
    return raise_on_error(result)
  end

  def associate_address(instance_id, public_ip)
    logger.trace "AssociateAddress('InstanceId' => #{instance_id.inspect}, 'PublicIp' => #{public_ip.inspect})"
    result = @client.AssociateAddress('InstanceId' => instance_id, 'PublicIp' => public_ip)
    logger.trace result.inspect
    return raise_on_error(result)
  end

  #TODO: Add stubs for all other Ec2 WS operations here, see http://s3.amazonaws.com/ec2-downloads/2010-11-15.ec2.wsdl

end

