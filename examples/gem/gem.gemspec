# frozen_string_literal: true

root = File.expand_path(__dir__)
$LOAD_PATH.push(File.expand_path('lib', root))
require 'gem/version'

Gem::Specification.new do |s|
  s.name = 'example'
  s.version = GEM::VERSION

  s.authors = ['Foo Bar']
  s.email = ['foobar@gmail.com']
  s.homepage = 'http://rubygems.org'
  s.license = 'MIT'
  s.metadata['rubygems_mfa_required'] = 'true'

  s.summary = 'Example'
  s.description = 'Example gem'
  s.files = Dir['lib/**/*']

  s.require_paths = ['lib']
  s.required_ruby_version = Gem::Requirement.new('>= 2.6')

  s.add_dependency 'i18n', '~> 1.14'
  s.add_dependency 'rake', '~> 10'
end
