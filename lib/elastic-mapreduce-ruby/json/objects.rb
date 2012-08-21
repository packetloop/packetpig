#
# JSON Objects
#  Copyright (C) 2003,2005 Rafael R. Sevilla <dido@imperium.ph>
#  This file is part of JSON for Ruby
#
#  JSON for Ruby is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public License
#  as published by the Free Software Foundation; either version 2.1 of
#  the License, or (at your option) any later version.
#
#  JSON for Ruby is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details. 
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with JSON for Ruby; if not, write to the Free
#  Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
#  02111-1307 USA.
#
# Author:: Rafael R. Sevilla (mailto:dido@imperium.ph)
# Heavily modified by Adam Kramer (mailto:adam@the-kramers.net)
# Copyright:: Copyright (c) 2003,2005 Rafael R. Sevilla
# License:: GNU Lesser General Public License
#


class Object
  def to_json #all strings in json need to have double quotes around them, treat random objects as strings
    String.to_json(to_s)
  end
end


class NilClass
  def to_json
    "null"
  end
end
class TrueClass
  def to_json
    "true"
  end
end

class FalseClass
  def to_json
    "false"
  end
end

class Numeric
  def to_json
    to_s
  end
end

class String
    # produce a string in double quotes with all the necessary quoting
    # done
    def to_json
      return String.to_json(self)
    end

    def self.to_json(str)
      return "\"\"" if (str.length == 0)
      newstr = "\""
      str.each_byte {
	|b|
	c = b.chr
	case c
	when /\\|\"|\//
	  newstr << "\\" + c
	when "\b"
	  newstr << "\\b"
	when "\t"
	  newstr << "\\t"
	when "\n"
	  newstr << "\\n"
	when "\f"
	  newstr << "\\f"
	when "\r"
	  newstr << "\\r"
	else
	  if (c < ' ')
	    t = "000" + sprintf("%0x", b)
	    newstr << ("\\u" + t[0,t.length - 4])
	  else
	    newstr << c
	  end
	end
      }
      newstr += '"'
      return(newstr)
    end
end

class Array

    # This method will return a string giving the contents of the JSON
    # array in standard JSON format.
    def to_json
      retval = '['

      first=true
      self.each { |obj|
	retval << ',' unless first
	retval << obj.to_json
	first=false
      }
      retval << "]"
      return(retval)
    end

    # This method will parse a JSON array from the passed lexer
    # object.  It takes a lexer object which is about to read a JSON
    # array.  It raises a runtime error otherwise.  It returns the
    # original JSON array. This method is not intended to be used
    # directly.
    # =====Parameters
    # +lexer+:: Lexer object to use
    def from_json(lexer)
      raise "A JSON Array must begin with '['" if (lexer.nextclean != "[")
      return (self) if lexer.nextclean == ']'
      lexer.back
      loop {
	self << lexer.nextvalue
	case lexer.nextclean
	when ','
	  return(self) if (lexer.nextclean == ']')
	  lexer.back
	when ']'
	  return(self)
	else
	  raise "Expected a ',' or ']'"
	end
      }
    end
end




class Hash

    # This method will serialize the hash into regular JSON format.
    def to_json
      retval = "{"

      first = true
      self.each {|key, val|
 	retval << "," unless first
	key = key.to_s #keys in json hashes need to be strings, nothing else.
 	retval << key.to_json + ":"
 	retval << val.to_json
	first = false
      }
      retval << "}"
      return(retval)
    end

    # This method will parse a JSON object from the passed lexer
    # object.  It takes a lexer object which is about to read a JSON
    # object.  It raises a runtime error otherwise.  It returns the
    # original JSON object.  This method probably shouldn't be used
    # directly.
    # =====Parameters
    def from_json(lexer)
      lexer.unescape if (lexer.nextclean == '%')
      lexer.back
      raise "A JSON Object must begin with '{'" if (lexer.nextclean != "{")
      loop {
	c = lexer.nextclean
	key = nil
	case c
	when '\0'
	  raise "A JSON Object must end with '}'"
	when '}'
	  return (self);
	else
	  lexer.back
	  key = lexer.nextvalue().to_s()
	end
	raise "Expected a ':' after a key" if (lexer.nextclean() != ':')
	self[key] = lexer.nextvalue()
	case lexer.nextclean()
	when ','
	  return(self) if (lexer.nextclean() == '}')
	  lexer.back
	when '}'
	  return(self)
	else
	  raise "Expected a ',' or '}'"
	end
      }
      return(self)
    end

end

