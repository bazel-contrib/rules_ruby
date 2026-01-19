# frozen_string_literal: true

require "hello_world"

# Test that the Git-sourced hello_world gem works correctly
speaker = HelloWorld::Speaker.new("Bazel")
expected = "Hello, Bazel"
actual = speaker.message

if actual == expected
  puts "PASS: Got expected message '#{actual}'"
  exit 0
else
  puts "FAIL: Expected '#{expected}', got '#{actual}'"
  exit 1
end
