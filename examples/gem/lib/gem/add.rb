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
  raise "Pass two numbers to sum: #{ARGV}" unless ARGV.size == 2

  puts GEM::Add.new(*ARGV.map(&:to_i)).result
end
