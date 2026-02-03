# frozen_string_literal: true

require_relative "lib/hello_world/version"

Gem::Specification.new do |s|
  s.name = "hello_world"
  s.version = HelloWorld::VERSION

  s.authors = ["Foo Bar"]
  s.email = ["foobar@gmail.com"]
  s.homepage = "http://rubygems.org"
  s.license = "MIT"
  s.metadata["rubygems_mfa_required"] = "true"

  s.summary = "Example"
  s.description = "Example gem"
  s.files = Dir["lib/**/*"] + Dir["bin/*"]
  s.executables = ["hello_world"]

  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6")

  s.add_dependency "irb"
  s.add_dependency "rspec", "~> 3.0"
end
