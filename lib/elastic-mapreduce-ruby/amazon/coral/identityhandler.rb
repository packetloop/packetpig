#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'amazon/coral/handler'

module Amazon
  module Coral

    # Preloads identity information into request objects.  Useful if all
    # requests through a client will utilize the same identity.
    class IdentityHandler < Handler

      # Instantiates an IdentityHandler with a hash of identity attributes
      # to be contributed to the request's identity.  Attributes specified
      # here will not override those explicitly associated with a request.
      def initialize(attributes)
        @attributes = attributes.to_hash
      end

      def before(job)
        identity = job.request[:identity]

        # for each shared identity attribute, set it on the request's
        # identity IFF no attribute with that key is already present
        @attributes.each { |k,v|
          identity[k] = v unless identity.has_key?(k)
        }
      end
    end
  end
end

