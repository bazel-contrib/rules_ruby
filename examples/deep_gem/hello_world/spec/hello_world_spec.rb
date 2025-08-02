# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/hello_world"

RSpec.describe HelloWorld do
  it "has a version number" do
    expect(HelloWorld::VERSION).not_to be nil
  end
end
