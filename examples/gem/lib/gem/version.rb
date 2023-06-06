# frozen_string_literal: true

module GEM
  VERSION = '0.1.0'
end

if __FILE__ == $PROGRAM_NAME
  puts "Ruby is: #{RUBY_ENGINE}/#{RUBY_VERSION}"
  puts "Java version is: #{ENV_JAVA['java.version']}" if Object.const_defined?(:ENV_JAVA)
  puts "Version is: #{GEM::VERSION}"
end
