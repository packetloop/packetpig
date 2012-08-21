#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

module Amazon
  module Coral

    class Job
      def initialize(request)
        @request = request
        @reply = {}
      end

      # Returns the hash of request attributes
      def request
        @request
      end

      # Returns the hash of reply attributes
      def reply
        @reply
      end
    end

  end
end
