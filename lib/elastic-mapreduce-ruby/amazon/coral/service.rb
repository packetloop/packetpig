#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'amazon/coral/option'
require 'amazon/coral/orchestrator'
require 'amazon/coral/dispatcher'
require 'amazon/coral/call'
require 'amazon/coral/awsquery'
require 'amazon/coral/simplelog'

module Amazon
  module Coral

    # Provides a simple command-line interface to call remote services.
    class Service

      @@command_arguments = [
                             Option.new({:long => 'help', :short => 'h'}),
                             Option.new({:long => 'url', :short => 'u', :parameters => 1}),
                             Option.new({:long => 'awsAccessKey', :short => 'a', :parameters => 1}),
                             Option.new({:long => 'awsSecretKey', :short => 's', :parameters => 1}),
                             Option.new({:long => 'v0'}),
                             Option.new({:long => 'v1'}),
                             Option.new({:long => 'timeout', :parameters => 1}),
                             Option.new({:long => 'connect_timeout', :parameters => 1}),
                             Option.new({:long => 'input', :short => 'i', :parameters => 1}),
                             Option.new({:long => 'operation', :short => 'o', :parameters => 1}),
                             Option.new({:long => 'verbose', :short => 'v'})];

      # Initializes a Service object with the specified arguments.
      # Possible arguments include:
      # [:orchestrator_helper]
      #   A class that responds to self.new_orchestrator create the necessary orchestrator.
      #   By default the AwsQueryChainHelper is used.
      # [:service]
      #   The name of the service to be called.
      # [:operations]
      #   A list naming the operations available on the remote service.
      def initialize(args)
        @orchestrator_helper_class = args[:orchestrator_helper]
        @orchestrator_helper_class = AwsQuery if @orchestrator_helper_class.nil?

        @service_name = args[:service]
        @operation_names = args[:operations]
      end

      # Runs the command line client application.
      def main

        if ARGV.length == 0 then
          print_usage
          exit
        end

        args = Option.parse(@@command_arguments, ARGV)
        if(args.length == 0 || !args['help'].nil?) then
          print_usage
          exit
        end



        raise "the 'url' parameter is required" if(args['url'].nil?)
        url = args['url'][0]
        
        input = nil
        input = eval(args['input'][0]) unless args['input'].nil?

        raise "the 'operation' parameter is required" if(args['operation'].nil?)
        operation = args['operation'][0]
        raise "operation '#{operation}' is not valid for this service" unless @operation_names.include?(operation)

        verbose = !args['verbose'].nil?

        timeout = Float(args['timeout'][0]) unless args['timeout'].nil?
        connect_timeout = Float(args['connect_timeout'][0]) unless args['connect_timeout'].nil?

        aws_access_key = nil
        aws_secret_key = nil
        signature_algorithm = nil

        if(!args['awsAccessKey'].nil? && !args['awsSecretKey'].nil?) then
          aws_access_key = args['awsAccessKey'][0]
          aws_secret_key = args['awsSecretKey'][0]
          signature_algorithm = :V2
          signature_algorithm = :V0 if !args['v0'].nil?
          signature_algorithm = :V1 if !args['v1'].nil?
        end

        helper_args = {:endpoint => url, :signature_algorithm => signature_algorithm, :verbose => verbose, :timeout => timeout, :connect_timeout => connect_timeout}

        orchestrator = @orchestrator_helper_class.new_orchestrator(helper_args)
        dispatcher = Dispatcher.new(orchestrator, @service_name, operation)
        call = Call.new(dispatcher)

        call.identity[:aws_access_key] = aws_access_key
        call.identity[:aws_secret_key] = aws_secret_key

        output = call.call(input)

        puts output.inspect
      end



      # Prints to STDOUT a help message describing how to use the application.
      def print_usage
        puts "#{@service_name} ruby client"
        puts "Usage:"
        puts "  -h --help"
        puts "  -u --url"
        puts "  -o --operation OPERATION"
        puts "  -i --input INPUT"
        puts "  -a --awsAccessKey KEY"
        puts "  -s --awsSecretKey SECRET_KEY"
        puts "  --v0"
        puts "  --v1"
        puts "  -v --verbose"
        puts ""
        puts "Available operations:"
        @operation_names.each { |name|
          puts("  #{name}")
        } unless @operation_names.nil?
      end

    end

  end
end

