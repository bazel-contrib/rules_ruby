#!/usr/bin/env ruby
# frozen_string_literal: true

require 'i18n'

module GEM
  class Add # :nodoc:
    def initialize(a, b) # rubocop:disable Naming/MethodParameterName
      @a = a
      @b = b
    end

    def result
      @a + @b
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  raise "Pass two numbers to sum: #{ARGV}" if ARGV.size < 2

  one, two, output = *ARGV
  result = GEM::Add.new(Integer(one), Integer(two)).result
  if output
    File.write(output, result)
  else
    puts result
  end
end
