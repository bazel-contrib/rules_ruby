#!/usr/bin/env ruby
# frozen_string_literal: true

# Bazel Ruby Runtime Setup
#
# This file sets up the Bazel runtime environment for Ruby applications.
# It should be required early in the application boot process.
#
# Usage:
#   if ENV["RUNFILES_DIR"]
#     setup_path = File.join(
#       ENV["RUNFILES_DIR"],
#       "rules_ruby",
#       "ruby",
#       "runtime",
#       "setup.rb",
#     )
#     require setup_path if File.exist?(setup_path)
#   end

# DEBUG BEGIN
warn("*** CHUCK setup.rb MADE IT")
# DEBUG END

# return unless ENV["RUNFILES_DIR"]

# runtime_dir = File.join(ENV["RUNFILES_DIR"], "rules_ruby", "ruby", "runtime")

# # DEBUG BEGIN
# warn("*** CHUCK runtime_dir: #{runtime_dir}")
# # DEBUG END

# # Load Bazel sandbox patches
# patches_path = File.join(runtime_dir, "bazel_patches.rb")
# # DEBUG BEGIN
# warn("*** CHUCK patches_path: #{patches_path}")
# # DEBUG END
# require patches_path

# # Load bytecode loader if manifest is present
# loader_path = File.join(runtime_dir, "bytecode_loader.rb")
# require loader_path

require_relative "bazel_patches"
require_relative "bytecode_loader"
