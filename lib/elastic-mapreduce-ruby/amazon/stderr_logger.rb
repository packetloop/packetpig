#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

module Amazon
  class StdErrLogger
    INFO = { :level => 4, :string => "INFO" }

    def initialize(level=nil)
      @level = level || INFO[:level]
      @file  = STDERR
    end

    def message(level, msg)
      if level[:level] <= @level then
        @file.puts(level[:string] + " " + msg)
      end
    end

    def info(*args)
      message(INFO, *args)
    end
  end
end
