# frozen_string_literal: true

# This doesnt use bazel sandbox files, it reads from the source tree.
require_relative 'spec_helper'

# Comment out require_relative and comment this in, it fails:
# LoadError:
# no such file to load -- spec_helper
# Until you add back spec_helper into the rb_test deps
# require 'spec_helper'

RSpec.describe GEM::Add do
  describe '#result' do
    specify do
      expect(GEM::Add.new(2, 2).result).to eq(4)
    end
  end
end
