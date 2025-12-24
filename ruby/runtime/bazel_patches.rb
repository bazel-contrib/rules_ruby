#!/usr/bin/env ruby
# frozen_string_literal: true

# Bazel Ruby patches for sandbox compatibility
#
# These patches fix issues with require_relative and __dir__ in Bazel's
# sandboxed environment. Without these patches, require_relative bypasses
# the sandbox by reading files directly from the source tree instead of
# the runfiles tree.
#
# See: https://github.com/bazel-contrib/rules_ruby/issues/225

$LOAD_PATH.uniq!

# Patch File.expand_path to resolve paths relative to the RUNFILES_DIR.
unless File.singleton_class.method_defined?(:rules_ruby_original_expand_path)
  File.singleton_class.class_eval do
    alias_method :rules_ruby_original_expand_path, :expand_path

    def bazel_runfiles_dir
      @bazel_runfiles_dir ||= ENV["RUNFILES_DIR"]
    end

    def bazel_workspace_name
      @bazel_workspace_name || ENV["BAZEL_WORKSPACE"]
    end

    def expand_path(path, dir = nil)
      dir = if dir && File.absolute_path?(dir)
        dir
      elsif dir && bazel_workspace_name && bazel_runfiles_dir
        # Assume that the relative dir is under the workspace.
        File.join(bazel_runfiles_dir, bazel_workspace_name, dir)
      else
        bazel_runfiles_dir
      end
      rules_ruby_original_expand_path(path, dir)
    end
  end
end

module Kernel
  unless respond_to?(:rules_ruby_bazel_patches_applied?)
    def rules_ruby_bazel_patches_applied?
      true
    end

    alias_method :rules_ruby_original_require_relative, :require_relative
    alias_method :rules_ruby_original___dir__, :__dir__

    def require_relative(path)
      base = caller_locations(1..1).first&.path
      base = "" if base.nil?

      # For bytecode-embedded paths with bazel-out prefix, use patched
      # File.expand_path The File.expand_path patch will handle path
      # normalization
      base_directory = File.dirname(base)
      require File.expand_path(path, base_directory)
    end

    def __dir__
      path = caller_locations(1..1).first&.path
      File.dirname(path || "")
    end
  end
end
