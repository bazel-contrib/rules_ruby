# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe File do
  specify do
    expect(File.read('spec/support/file.txt').chomp).to eq('File!')
  end
end
