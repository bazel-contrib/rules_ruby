# frozen_string_literal: true

require 'greeter'

RSpec.describe Greeter do
  specify do
    expect(described_class.greet('Bazel')).to eq('Hello, Bazel!')
  end

  specify 'Bundler and the library agree on the version' do
    expect(Gem.loaded_specs.fetch('greeter').version.to_s).to eq(Greeter::VERSION)
  end

  specify 'the version is stamped only into release builds' do
    expect(Greeter::VERSION).to eq(ENV.fetch('EXPECTED_VERSION'))
  end
end
