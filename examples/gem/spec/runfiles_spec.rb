# frozen_string_literal: true

require_relative 'spec_helper'
require 'bazel/runfiles'

RSpec.describe Bazel::Runfiles do
  subject(:runfiles) { described_class.create }

  specify do
    path = runfiles.rlocation(ENV.fetch('RLOCATIONPATH_DATA'))

    expect(File).to exist(path)
    expect(File.read(path).chomp).to eq('File!')
  end

  specify do
    path = runfiles.rlocation(ENV.fetch('RLOCATIONPATH_DEP'))

    expect(File).to exist(path)
  end

  specify do
    path = runfiles.rlocation(ENV.fetch('RLOCATIONPATH_DATA'))

    expect(runfiles.rlocation(path)).to eq(path)
  end

  specify do
    expect { runfiles.rlocation('') }.to raise_error(ArgumentError)
  end
end
