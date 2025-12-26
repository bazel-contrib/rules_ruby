#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

# Merge app and gem bytecode manifests
#
# Usage: merge_manifests.rb <app_manifest> <gem_manifest> <output_manifest>
#
# Arguments:
#   app_manifest: Path to app bytecode manifest JSON
#   gem_manifest: Path to gem bytecode manifest JSON (optional, can be empty string)
#   output_manifest: Path to write merged manifest

app_manifest_path = ARGV[0]
gem_manifest_path = ARGV[1]
output_path = ARGV[2]

unless app_manifest_path && output_path
  warn "Usage: merge_manifests.rb <app_manifest> <gem_manifest> <output>"
  exit 1
end

# Read app manifest
app_data = JSON.parse(File.read(app_manifest_path))
merged_entries = app_data["entries"] || {}

# Read and merge gem manifest if provided
if gem_manifest_path && !gem_manifest_path.empty? && File.exist?(gem_manifest_path)
  gem_data = JSON.parse(File.read(gem_manifest_path))
  gem_entries = gem_data["entries"] || gem_data["mappings"] || {}

  # Merge gem entries (app entries take precedence if there are conflicts)
  gem_entries.each do |key, value|
    merged_entries[key] ||= value
  end
end

# Write merged manifest
output_data = {
  "version" => 1,
  "entries" => merged_entries,
}

File.write(output_path, JSON.pretty_generate(output_data))
