# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/hello_world"

RSpec.describe HelloWorld::Speaker do
  describe "#name" do
    context "when no name is provided" do
      it "defaults to 'world'" do
        speaker = HelloWorld::Speaker.new
        expect(speaker.name).to eq("world")
      end
    end

    context "when a name is provided" do
      it "uses the provided name" do
        name = "Jimmy"
        speaker = HelloWorld::Speaker.new(name)
        expect(speaker.name).to eq(name)
      end
    end
  end
end
