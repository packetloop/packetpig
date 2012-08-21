#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

class SimpleExecutor
  def exec(cmd)
    puts(cmd)
    if ! system(cmd) then
      raise RuntimeError, "Command failed."
    end
  end
end
