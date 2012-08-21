#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.
require 'cgi'

module Amazon
  module Coral

    # Performs AWS's preferred method of URLEncoding.
    class UrlEncoding
      
      # Convert a string into URL encoded form.
      def UrlEncoding.encode(plaintext)
        CGI.escape(plaintext.to_s).gsub("+", "%20").gsub("%7E", "~")
      end
    end
    
  end
end

