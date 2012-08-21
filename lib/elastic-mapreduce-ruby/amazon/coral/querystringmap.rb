#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'amazon/coral/urlencoding'

module Amazon
  module Coral

    # A hash containing query string parameters that produces a query
    # string via to_s.  Also consumes hashes representing hierarchies of
    # data to encode as query parameters.
    class QueryStringMap < Hash

      # Instantiate a QueryStringMap with the contents of the specified
      # hash.  If no hash is provided, an empty map is created.
      def initialize(hash = {})
        add_flattened(hash)
      end

      # Returns the query string representation of this map by collapsing
      # its key-value pairs into URL parameters.
      def to_s
        qstr = ''
        isFirst = true
        each_pair { |k,v|
          if isFirst then
            isFirst = false
          else
            qstr << '&'
          end
          qstr << UrlEncoding.encode(k.to_s)
          unless(v.nil?) then
            qstr << '='
            qstr << UrlEncoding.encode(v.to_s)
          end
        }
        return qstr
      end

      private
      def add_flattened(hash)
        stack = []
        add_flattened_helper(stack, hash)
      end

      def add_flattened_helper(stack, obj)
        return if obj.nil?
        
        case obj
        when Hash:

            obj.each_pair { |k,v|
            stack.push(k)
            add_flattened_helper(stack, v)
            stack.pop
          }

        when Array:

            # Do artificial list member wrapping (Coral requires this
            # level of indirection, but doesn't validate the member name)
            stack.push("member")

          obj.each_index { |i|
            v = obj[i]
            stack.push(i + 1) # query string arrays are 1-based
            add_flattened_helper(stack, v)
            stack.pop
          }

          stack.pop

        else

          # this works for symbols also, because sym.id2name == sym.to_s
          self[get_key(stack)] = obj.to_s

        end
      end

      def get_key(stack)
        key = ''
        stack.each_index { |i|
          key << '.' if(i > 0)
          key << stack[i].to_s
        }
        return key
      end

    end

  end
end
