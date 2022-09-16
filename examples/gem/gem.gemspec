root = File.expand_path(__dir__)
$LOAD_PATH.push(File.expand_path('lib', root))
require 'gem/version'

Gem::Specification.new do |s|
  s.name = 'example'
  s.version = GEM::VERSION

  s.authors = ['Alex Rodionov']
  s.email = ['p0deje@gmail.com']

  s.summary = 'Example'
  s.description = 'Example'
  s.files = ['Gemfile'] + Dir['lib/gem/**/*']

  s.require_paths = ['lib']

  s.add_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'
end
