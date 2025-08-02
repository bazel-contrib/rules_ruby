# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/hello_world"

RSpec.describe HelloWorld::Speaker, "name" do
  it "defaults to 'world'" do
    speaker = HelloWorld::Speaker.new
    expect(speaker.name).to eq("world")
  end

  it "can be customized" do
    name = "Jimmy"
    speaker = HelloWorld::Speaker.new(name)
    expect(speaker.name).to eq(name)
  end
end
