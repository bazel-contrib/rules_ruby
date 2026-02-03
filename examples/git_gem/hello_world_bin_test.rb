binary = File.join(ENV["TEST_SRCDIR"], ARGV[0])
output = `#{binary} 2>&1`
raise "Binary exited with code #{$?.exitstatus}: #{output}" unless $?.success?
raise "Expected 'Hello, World', got '#{output.strip}'" unless output.include?("Hello, World")
puts "PASS: Got expected output 'Hello, World'"
