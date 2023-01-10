# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe GEM::Add do
  describe '#result' do
    specify do
      expect(GEM::Add.new(2, 2).result).to eq(4)
    end
  end
end
