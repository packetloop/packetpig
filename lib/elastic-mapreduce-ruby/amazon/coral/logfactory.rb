#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'logger'

module Amazon
module Coral

# A simple log retrieval interface to allow injection of common logging frameworks.
class LogFactory

  @@instance = LogFactory.new

  # Invokes the singleton LogFactory instance to retrieve a logger for a given key.
  def LogFactory.getLog(key)
    return @@instance.getLog(key)
  end

  # Specifies a LogFactory instance which will handle log requests.
  # Call this method early in execution prior to instantiating handlers to replace the default no-op log.
  def LogFactory.setInstance(instance)
    @@instance = instance
  end

  # Default logging implementation which returns a null logger.
  def getLog(key)
    log = Logger.new(nil)
    log.level = Logger::FATAL
    return log
  end

end

end
end
