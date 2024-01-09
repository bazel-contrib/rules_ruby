# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe ENV do
  specify do
    expect(ENV.fetch('EXAMPLE')).to eq('ENV')
  end

  specify do
    expect(ENV).to have_key('USER').or have_key('USERNAME')
  end

  specify do
    expect(ENV.fetch('BUNDLE_BUILD__FOO')).to eq('bar')
  end
end
