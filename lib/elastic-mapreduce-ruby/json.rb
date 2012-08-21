#
# Copyright 2008-2010 Amazon.com, Inc. or its affiliates.  All Rights Reserved.

require 'json/objects'
require 'json/lexer'
require 'stringio'

module JSON
  def self.parse(str)
    return Lexer.new(str).nextvalue
  end

  def self.pretty_generate(obj)
    s = []
    self.pretty_generate_recursive(obj, s, "")
    return s.join("")
  end

  def self.pretty_generate_recursive(obj, stream, indent)
    if obj.is_a?(Hash) then
      if obj.size == 0 then
        stream << "{}"
      else
        stream << "{\n" 
        first = true
        for key, value in obj do
          if first then
            first = false
          else
            stream << "," << "\n"
          end
          stream << indent << "  " << key.to_json.chomp << ": "
          self.pretty_generate_recursive(value, stream, indent + "  ")
        end
        stream << "\n" << indent << "}"
      end
    elsif obj.is_a?(Array)
      if obj.size == 0 then
        stream << "[]"
      else
        stream << "[\n" 
        first = true
        for value in obj do
          if first then
            first = false
          else
            stream << "," << "\n"
          end
          stream << indent + "  "
          self.pretty_generate_recursive(value, stream, indent + "  ")
        end
        stream << "\n" << indent << "]"
      end
    else
      stream << obj.to_json.chomp
    end
  end
end
