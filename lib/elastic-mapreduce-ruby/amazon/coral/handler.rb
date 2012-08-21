#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

module Amazon
  module Coral
    
    class Handler
      
      # Operate on the specified Job on the "outbound" side of the execution
      def before(job)
      end
      
      # Operation on the specified Job on the "inbound" side of the execution
      def after(job)
      end
      
    end
    
  end
end
