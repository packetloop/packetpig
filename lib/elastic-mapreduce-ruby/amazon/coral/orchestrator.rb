#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'amazon/coral/job'
require 'amazon/coral/logfactory'

module Amazon
  module Coral
    
    # Directs a Job through a Handler chain for processing.
    class Orchestrator
      
      # Instantiate an orchestrator with the given list of Handlers.
      def initialize(handlers)
        @log = LogFactory.getLog('Amazon::Coral::Orchestrator')
        @handlers = handlers
        
        @log.info "Initialized with handlers: #{handlers}"
      end
      
      # Direct the specified request down the Handler chain, invoking first each before method,
      # then in reverse order each after method.  If any exceptions are thrown along the way, orchestration
      # will stop immediately.
      def orchestrate(request)
        @log.debug "Processing request #{request}"
        
        job = Job.new(request)
        
        stack = []
        
        @handlers.each { |handler|
          stack << handler
          
          @log.debug "Invoking #{handler}.before()"
          handler.before(job)
        }
        
        stack.reverse.each { |handler|
          @log.debug "Invoking #{handler}.after()"
          handler.after(job)
        }
        
        return job.reply
      end
      
    end
    
  end
end
