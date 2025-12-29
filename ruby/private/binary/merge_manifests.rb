#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

# Merge app and gem bytecode manifests
#
# Usage: merge_manifests.rb <app_manifest> <gem_manifest> <output_manifest>
#
# Arguments:
#   app_manifest: Path to app bytecode manifest (JSON format from Starlark)
#   gem_manifest: Path to gem bytecode manifest (Marshal format, optional)
#   output_manifest: Path to write merged manifest (Marshal format)

# Load manifest from file, auto-detecting format (Marshal or JSON)
def load_manifest(path)
  content = File.binread(path)
  # Try Marshal first (binary format starts with specific bytes)
  Marshal.load(content)
rescue TypeError, ArgumentError
  # Fall back to JSON if Marshal fails
  JSON.parse(content)
end

app_manifest_path = ARGV[0]
gem_manifest_path = ARGV[1]
output_path = ARGV[2]

unless app_manifest_path && output_path
  warn "Usage: merge_manifests.rb <app_manifest> <gem_manifest> <output>"
  exit 1
end

# Read app manifest (JSON from Starlark)
app_data = load_manifest(app_manifest_path)
merged_entries = app_data["entries"] || {}

# Read and merge gem manifest if provided
if gem_manifest_path && !gem_manifest_path.empty? && File.exist?(gem_manifest_path)
  gem_data = load_manifest(gem_manifest_path)
  gem_entries = gem_data["entries"] || gem_data["mappings"] || {}

  # Merge gem entries (app entries take precedence if there are conflicts)
  gem_entries.each do |key, value|
    merged_entries[key] ||= value
  end
end

# Write merged manifest (Marshal format for fast loading at runtime)
output_data = {
  "version" => 1,
  "entries" => merged_entries,
}

File.binwrite(output_path, Marshal.dump(output_data))
