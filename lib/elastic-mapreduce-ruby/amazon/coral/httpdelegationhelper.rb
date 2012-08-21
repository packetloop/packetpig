#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

module Amazon
  module Coral
    
    class HttpDelegationHelper
      def self.add_delegation_token(delegate_identity, request_identity)
        token = ""
        first = true
        
        delegate_identity.each do |k,v|
          if(first)
            first = false
          else
            token << ';'
          end
          
          token << "#{k}=#{v}"
        end
        
        request_identity[:http_delegation] = token if(token.length > 0)
      end
    end
    
  end
end
