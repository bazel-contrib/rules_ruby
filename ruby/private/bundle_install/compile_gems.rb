#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "pack_bytecode"

# Compile all .rb files in bundle gems to bytecode pack
#
# Usage: compile_gems.rb <bundle_path> <output_pack>
#
# Arguments:
#   bundle_path: Path to vendor/bundle directory
#   output_pack: Path to write bytecode pack file

bundle_path = ARGV[0]
output_pack = ARGV[1]

unless bundle_path && output_pack
  warn "Usage: compile_gems.rb <bundle_path> <output_pack>"
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

packer = BytecodePacker.new(output_pack)
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

  begin
    # Compile to bytecode with custom embedded path (without bazel-out prefix)
    # This ensures __FILE__ resolves correctly at runtime in runfiles
    source = File.read(src_path)
    embed_path = embed_path_for_bytecode(src_path)
    iseq = RubyVM::InstructionSequence.compile(source, embed_path)

    # Add to pack
    packer.add(src_key, iseq.to_binary)
    compiled_count += 1
  rescue SyntaxError
    # Skip files with syntax errors (test fixtures, examples, etc.)
    failed_count += 1
  rescue => e
    warn "[compile_gems.rb] Failed to compile #{src_key}: #{e.class} - #{e.message}"
    failed_count += 1
  end
end

packer.write

warn "[compile_gems.rb] Compiled #{compiled_count} files, #{failed_count} failed"
warn "[compile_gems.rb] Pack written to #{output_pack}"

# Only exit with error if no files were successfully compiled
# Some gems include test fixtures or example code with syntax errors
if compiled_count == 0 && failed_count > 0
  warn "[compile_gems.rb] ERROR: No files were successfully compiled"
  exit 1
end

exit 0
