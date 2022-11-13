# frozen_string_literal: true

module GEM
  VERSION = '0.1.0'
end

if __FILE__ == $PROGRAM_NAME
  puts "Ruby is: #{RUBY_ENGINE}/#{RUBY_VERSION}"
  puts "Version is: #{GEM::VERSION}"
end
