require_relative "spec_helper"

RSpec.describe ENV do
  specify do
    expect(ENV['EXAMPLE']).to eq('ENV')
  end

  specify do
    expect(ENV['LANG']).not_to be_empty
  end
end
