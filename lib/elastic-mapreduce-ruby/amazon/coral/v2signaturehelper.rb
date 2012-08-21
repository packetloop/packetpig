#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'openssl'
require 'base64'
require 'time'

module Amazon
  module Coral

    # Performs AWS V2 signatures on QueryStringMap objects.
    class V2SignatureHelper 
      def initialize(aws_access_key_id, aws_secret_key)
        @aws_access_key_id = aws_access_key_id.to_s
        @aws_secret_key = aws_secret_key.to_s
      end

      def sign(args)
        signT(Time.now.iso8601, args)
      end

      def signT(time, args)
        query_string_map = args[:query_string_map]
        add_fields(query_string_map, time)
        query_string_map['Signature'] = compute_signature(canonicalize(args))
      end

      def canonicalize(args)
        query_string_map = args[:query_string_map]
        uri = args[:uri]
        verb = args[:verb]
        host = args[:host].downcase

        # exclude any existing Signature parameter from the canonical string
        sorted = sort(query_string_map.reject { |k, v| k == 'Signature' })
        
        canonical = "#{verb}\n#{host}\n#{uri}\n"
        isFirst = true

        sorted.each { |v|
          if(isFirst) then
            isFirst = false
          else
            canonical << '&'
          end

          canonical << UrlEncoding.encode(v[0])
          unless(v[1].nil?) then
            canonical << '='
            canonical << UrlEncoding.encode(v[1])
          end
        }

        return canonical
      end

      def compute_signature(canonical)
        digest = OpenSSL::Digest::Digest.new('sha256')
        return Base64.encode64(OpenSSL::HMAC.digest(digest, @aws_secret_key, canonical)).strip
      end

      def add_fields(query_string_map, time)
        query_string_map['AWSAccessKeyId'] = @aws_access_key_id
        query_string_map['SignatureVersion'] = '2'
        query_string_map['SignatureMethod'] = 'HmacSHA256'
        query_string_map['Timestamp'] = time.to_s
      end

      def sort(hash)
        hash.sort
      end

    end

  end
end
