require_relative "spec_helper"

RSpec.describe ENV do
  specify do
    expect(ENV['EXAMPLE']).to eq('ENV')
  end

  specify do
    expect(ENV).to have_key('USER').or have_key('USERNAME')
  end
end
