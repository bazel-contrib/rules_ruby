# frozen_string_literal: true

require 'greeter/version'

module Greeter
  def self.greet(name)
    "Hello, #{name}!"
  end
end
