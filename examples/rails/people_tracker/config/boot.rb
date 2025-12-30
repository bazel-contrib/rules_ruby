ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

# Load Bazel runtime support if in Bazel environment
rules_ruby_setup = ENV["RULES_RUBY_SETUP"]
require rules_ruby_setup if rules_ruby_setup

# # Skip bootsnap when using Bazel bytecode compilation
# require "bootsnap/setup" unless ENV["RUBY_BYTECODE_MANIFEST"]
