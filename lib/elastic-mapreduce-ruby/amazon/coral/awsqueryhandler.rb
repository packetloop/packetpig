#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'json/lexer'
require 'json/objects'
require 'rexml/document'
require 'amazon/coral/handler'
require 'amazon/coral/querystringmap'
require 'amazon/coral/logfactory'
require 'amazon/aws/exceptions'

module Amazon
  module Coral

    class AwsQueryHandler < Handler

      def initialize(args = {})
        @api_version = args[:api_version]
        @content_type = args[:content_type]

        @log = LogFactory.getLog('Amazon::Coral::AwsQueryHandler')
      end

      def before(job)
        request = job.request

        operation_name = request[:operation_name]

        query_string_map = QueryStringMap.new(request[:value])
        query_string_map['Action'] = operation_name.to_s
        if @content_type then
           query_string_map['ContentType'] = @content_type
        end
        if @api_version then
           query_string_map['Version'] = @api_version
        end

        request[:query_string_map] = query_string_map
        request[:http_verb] = 'POST'

        @log.info "Making request to operation #{operation_name} with parameters #{query_string_map}"
      end

      def after(job)
        operation_name = job.request[:operation_name]

        reply = job.reply

        @log.info "Received response body: #{reply[:value]}"

        json_result = nil
        begin
          if @content_type == 'JSON' then
            json_result = JSON::Lexer.new(reply[:value]).nextvalue
            reply[:value] = get_value(operation_name, json_result)
          else
            reply[:value] = convert_to_json(reply[:value])
          end
        rescue
          code = reply[:http_status_code]
          message = reply[:http_status_message]

          raise "#{code} : #{message}" unless code.to_i == 200
          raise "Failed parsing response: #{$!}\n"
        end

        aws_error?(reply[:response], reply[:value]) if @content_type != 'JSON'
      end

      private
      def get_value(operation_name, json_result)
        # If there was an error, unwrap it and return
        return {"Error" => json_result["Error"]} if json_result["Error"]

        # Otherwise unwrap the valid response
        json_result = json_result["#{operation_name}Response"]
        json_result = json_result["#{operation_name}Result"]
        return json_result
      end

      private 
      def convert_to_json(document)
        doc = REXML::Document.new(document)
        array = []
        doc.elements.each do |elem|
          array << xml_to_json(elem) if elem.kind_of?(REXML::Element)
        end
        raise "Failed parsing response: #{$!}\n" if array.length > 1
        
        return array.first
      end

      private 	
      def xml_to_json(parent)
        array  = []
        struct = {}
        parent.children.each do |elem|
          if elem.kind_of?(REXML::Element) then
            if elem.name == "item" then
              array << xml_to_json(elem)
            else
              if struct[elem.name] != nil then
                if ! struct[elem.name].is_a?(Array) then
                  struct[elem.name] = [ struct[elem.name] ]
                end
                struct[elem.name] << xml_to_json(elem)
              else
                struct[elem.name] = xml_to_json(elem)
              end
            end
          end
        end
        if array.size > 0 then
          return array
        elsif struct.keys.size > 0 then
          return struct
        else
          return parent.text
        end
      end
      
      private
      def aws_error?(response, body)
	# This method has been copied and adapted from:
	#--
	# Amazon Web Services EC2 + ELB API Ruby library
	#
	# Ruby Gem Name::  amazon-ec2
	# Author::    Glenn Rempe  (mailto:glenn@rempe.us)
	# Copyright:: Copyright (c) 2007-2009 Glenn Rempe
	# License::   Distributes under the same terms as Ruby
	# Home::      http://github.com/grempe/amazon-ec2/tree/master
	#++

        # return false if we got a HTTP 200 code,
        # otherwise there is some type of error (40x,50x) and
        # we should try to raise an appropriate exception
        # from one of our exception classes defined in
        # exceptions.rb
        return false if response.is_a?(Net::HTTPSuccess)

        raise RuntimeError, "Unexpected server error. response.body is: #{body}" if response.is_a?(Net::HTTPServerError)

        # Check that the Error element is in the place we would expect.
        # and if not raise a generic error exception
        unless body['Errors']['Error'].length >= 2
          raise RuntimeError, "Unexpected error format. response.body is: #{body}"
        end

        # An valid error response looks like this:
        # <?xml version="1.0"?><Response><Errors><Error><Code>InvalidParameterCombination</Code><Message>Unknown parameter: foo</Message></Error></ Errors><RequestID>291cef62-3e86-414b-900e-17246eccfae8</RequestID></Response>
        # AWS throws some exception codes that look like Error.SubError.  Since we can't name classes this way
        # we need to strip out the '.' in the error 'Code' and we name the error exceptions with this
        # non '.' name as well.
        error_code    = body['Errors']['Error']['Code']
        error_message = body['Errors']['Error']['Message']

        # Raise one of our specific error classes if it exists.
        # otherwise, throw a generic EC2 Error with a few details.
        if AWS.const_defined?(error_code)
          raise AWS.const_get(error_code), error_message
        else
          raise Error, error_message
        end
      end

    end

  end
end
