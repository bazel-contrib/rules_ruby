#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "fileutils"

# Compile all .rb files in bundle gems to bytecode
#
# Usage: compile_gems.rb <bundle_path> <output_dir> <manifest_output>
#
# Arguments:
#   bundle_path: Path to vendor/bundle directory
#   output_dir: Directory to write .rbc files (preserving structure)
#   manifest_output: Path to write JSON manifest of mappings

bundle_path = ARGV[0]
output_dir = ARGV[1]
manifest_output = ARGV[2]

unless bundle_path && output_dir && manifest_output
  warn "Usage: compile_gems.rb <bundle_path> <output_dir> <manifest_output>"
  exit 1
end

unless File.directory?(bundle_path)
  warn "Bundle path does not exist: #{bundle_path}"
  exit 1
end

# Find all .rb files in the gems directory
gems_dir = File.join(bundle_path, "ruby", "*", "gems")
rb_files = Dir.glob(File.join(gems_dir, "**", "*.rb"))

warn "[compile_gems.rb] Found #{rb_files.size} Ruby files in gems"

mappings = {}
compiled_count = 0
failed_count = 0

rb_files.each do |src_path|
  # Calculate relative path from bundle_path
  relative_path = src_path.delete_prefix("#{bundle_path}/")

  # Create output path with .rbc extension
  output_path = File.join(output_dir, relative_path + "c")

  # Ensure output directory exists
  FileUtils.mkdir_p(File.dirname(output_path))

  begin
    # Compile to bytecode
    iseq = RubyVM::InstructionSequence.compile_file(src_path)
    File.binwrite(output_path, iseq.to_binary)

    # Store mapping (relative paths within bundle)
    mappings[relative_path] = relative_path + "c"
    compiled_count += 1
  rescue SyntaxError => e
    # Skip files with syntax errors (test fixtures, examples, etc.)
    failed_count += 1
  rescue => e
    warn "[compile_gems.rb] Failed to compile #{relative_path}: #{e.class} - #{e.message}"
    failed_count += 1
  end
end

# Write manifest
manifest = {
  "version" => 1,
  "compiled" => compiled_count,
  "failed" => failed_count,
  "mappings" => mappings,
}

File.write(manifest_output, JSON.pretty_generate(manifest))

warn "[compile_gems.rb] Compiled #{compiled_count} files, #{failed_count} failed"
warn "[compile_gems.rb] Manifest written to #{manifest_output}"

# Only exit with error if no files were successfully compiled
# Some gems include test fixtures or example code with syntax errors
if compiled_count == 0 && failed_count > 0
  warn "[compile_gems.rb] ERROR: No files were successfully compiled"
  exit 1
end

exit 0
