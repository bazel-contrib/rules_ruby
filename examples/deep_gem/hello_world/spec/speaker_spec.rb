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
      it "returns the provided name" do
        name = "Jimmy"
        speaker = HelloWorld::Speaker.new(name)
        expect(speaker.name).to eq(name)
      end
    end
  end

  describe "#message" do
    context "when using default name" do
      it "returns a greeting with the default name" do
        speaker = HelloWorld::Speaker.new
        expect(speaker.message).to eq("Hello, world")
      end
    end

    context "when using custom name" do
      it "returns a greeting with the custom name" do
        speaker = HelloWorld::Speaker.new("Alice")
        expect(speaker.message).to eq("Hello, Alice")
      end
    end
  end

  describe "#hi" do
    context "when using default name" do
      it "outputs the greeting message to stdout" do
        speaker = HelloWorld::Speaker.new
        expect { speaker.hi }.to output("Hello, world\n").to_stdout
      end
    end

    context "when using custom name" do
      it "outputs the greeting message with custom name to stdout" do
        speaker = HelloWorld::Speaker.new("Bob")
        expect { speaker.hi }.to output("Hello, Bob\n").to_stdout
      end
    end
  end
end
