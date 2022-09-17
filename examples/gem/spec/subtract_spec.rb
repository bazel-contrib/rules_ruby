require_relative "spec_helper"

RSpec.describe GEM::Subtract do
  describe '#result' do
    specify do
      expect(GEM::Subtract.new(2, 2).result).to eq(0)
    end
  end
end
