# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

module Amazon
  module Coral

    # A simple library for processing command line arguments.
    class Option
      def initialize(args)
        @long = args[:long]
        @short = args[:short]
        @num_parameters = args[:parameters]
        @description = args[:description]
      end

      # Returns the long form of this option's name
      def long
        @long
      end
      # Returns the short form of this option's name
      def short
        @short
      end
      # Returns a text description of this option, if present
      def description
        @description
      end

      # Consume the arguments of this option from the argument vector and store them in the provided hash
      # Returns the incremented counter of current position within the argument vector.
      def consume(argv, i, hash)
        i = i + 1
        hash[@long] = []
        unless @num_parameters.nil?
          @num_parameters.times do
            raise "Option #{@long} requires #{@num_parameters} parameter(s)" if argv.length <= i
            hash[@long] << argv[i]
            i = i + 1
          end
        end

        return i
      end

      # Using the provided list of arguments (defined as Option objects), parse the given argument vector.
      def Option.parse(arguments, argv)
        long_map = {}
        short_map = {}
        arguments.each { |p|
          long_map["--#{p.long}"] = p unless p.long.nil?
          short_map["-#{p.short}"] = p unless p.short.nil?
        }


        h = {}
        i = 0
        while i < argv.length
          arg = argv[i]
          a = long_map[arg]
          a = short_map[arg] if a.nil?
          raise "Unrecognized argument '#{arg}'" if a.nil?

          i = a.consume(argv, i, h)
        end

        return h
      end
    end

  end
end
