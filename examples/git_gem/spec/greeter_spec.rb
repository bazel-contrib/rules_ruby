# frozen_string_literal: true

require "hello_world"

RSpec.describe HelloWorld::Speaker do
  it "returns the expected greeting" do
    speaker = HelloWorld::Speaker.new("Bazel")
    expect(speaker.message).to eq("Hello, Bazel")
  end
end
