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

EXTERNAL_PREFIX_REGEX = %r{^.*/external/}

def strip_external_prefix(path)
  path.sub(EXTERNAL_PREFIX_REGEX, "")
end

def embed_path_for_bytecode(path)
  # Strip the bazel-out/.../external/ prefix and add ../ so the path
  # resolves correctly from the working directory (xxx.runfiles/_main)
  "../" + strip_external_prefix(path)
end

rb_files.each do |src_path|
  # Calculate the src key for the mapping
  src_key = strip_external_prefix(src_path)

  # Calculate relative path from bundle_path
  out_rel_path = src_path.delete_prefix("#{bundle_path}/") + "c"
  # out_rel_path = src_key + "c"

  # Create output path with .rbc extension
  out_path = File.join(output_dir, out_rel_path)
  out_value = strip_external_prefix(out_path)

  # Ensure output directory exists
  FileUtils.mkdir_p(File.dirname(out_path))

  begin
    # Compile to bytecode with custom embedded path (without bazel-out prefix)
    # This ensures __FILE__ resolves correctly at runtime in runfiles
    source = File.read(src_path)
    embed_path = embed_path_for_bytecode(src_path)
    iseq = RubyVM::InstructionSequence.compile(source, embed_path)
    File.binwrite(out_path, iseq.to_binary)

    # Store mapping (relative paths within bundle)
    mappings[src_key] = out_value
    compiled_count += 1
  rescue SyntaxError
    # Skip files with syntax errors (test fixtures, examples, etc.)
    failed_count += 1
  rescue => e
    warn "[compile_gems.rb] Failed to compile \
    #{out_rel_path}: #{e.class} - #{e.message}"
    failed_count += 1
  end
end

# Write manifest
manifest = {
  "version" => 1,
  "compiled" => compiled_count,
  "failed" => failed_count,
  "mappings" => mappings
}

File.write(manifest_output, JSON.pretty_generate(manifest))

warn "[compile_gems.rb] Compiled #{compiled_count} files, " \
     "#{failed_count} failed"
warn "[compile_gems.rb] Manifest written to #{manifest_output}"

# Only exit with error if no files were successfully compiled
# Some gems include test fixtures or example code with syntax errors
if compiled_count == 0 && failed_count > 0
  warn "[compile_gems.rb] ERROR: No files were successfully compiled"
  exit 1
end

exit 0
