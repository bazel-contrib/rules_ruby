# frozen_string_literal: true

require "hello_world"

# Use the Git-sourced hello_world gem
speaker = HelloWorld::Speaker.new("World")
puts speaker.message
