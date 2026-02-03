# frozen_string_literal: true

RSpec.describe "hello_world binary" do
  it "prints the expected greeting" do
    binary = File.join(ENV["TEST_SRCDIR"], ENV["HELLO_WORLD_BIN"])
    output = `#{binary} 2>&1`
    expect($?.exitstatus).to eq(0), "Binary exited with code #{$?.exitstatus}: #{output}"
    expect(output).to include("Hello, World")
  end
end
