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

BAZEL_OUT_EXTERNAL_PREFIX_REGEX = %r{^bazel-out/.*/external/}
RULES_RUBY_GENERATED_REPO_PREFIX_REGEX = %r{^\.\./?rules_ruby\+\+}
RULES_RUBY_GENERATED_REPO_PREFIX = "rules_ruby++"

# Patch File.expand_path to resolve paths relative to the RUNFILES_DIR.
unless File.singleton_class.method_defined?(:rules_ruby_original_expand_path)
  File.singleton_class.class_eval do
    alias_method :rules_ruby_original_expand_path, :expand_path

    def bazel_runfiles_dir
      @bazel_runfiles_dir ||= ENV["RUNFILES_DIR"]
    end

    def bazel_workspace_name
      @bazel_workspace_name ||= ENV["BAZEL_WORKSPACE"]
    end

    def expand_path(path, dir = nil)
      # Convert Pathname objects to strings
      path = path.to_s
      dir = dir.to_s if dir

      dir = if dir
        if File.absolute_path?(dir)
          dir
        elsif dir.match?(BAZEL_OUT_EXTERNAL_PREFIX_REGEX)
          # TODO: Try to remove this case once everything is working.
          File.join(
            bazel_runfiles_dir,
            dir.sub(BAZEL_OUT_EXTERNAL_PREFIX_REGEX, "")
          )
        elsif dir.match?(RULES_RUBY_GENERATED_REPO_PREFIX_REGEX)
          # NOTE: This is not a great way to detect that the relative path is
          # outside of the source tree. It was either this or look for /gems/
          # in the path. 🤮
          # Path starts with ../rules_ruby++ - strip ../ and resolve from
          # runfiles
          File.join(
            bazel_runfiles_dir,
            dir.sub(
              RULES_RUBY_GENERATED_REPO_PREFIX_REGEX,
              RULES_RUBY_GENERATED_REPO_PREFIX
            )
          )
        elsif bazel_workspace_name && bazel_runfiles_dir
          # Assume that the relative dir is under the workspace.
          File.join(bazel_runfiles_dir, bazel_workspace_name, dir)
        else
          bazel_runfiles_dir
        end
      else
        bazel_runfiles_dir
      end

      if path.match?(RULES_RUBY_GENERATED_REPO_PREFIX_REGEX)
        path = path.sub(
          RULES_RUBY_GENERATED_REPO_PREFIX_REGEX,
          RULES_RUBY_GENERATED_REPO_PREFIX
        )
      end

      rules_ruby_original_expand_path(path, dir)
    end

    # Patch File.open to normalize relative bytecode paths to absolute paths.
    # This fixes issues where gems use File.open(__FILE__) for feature detection
    # (e.g., logger/log_device.rb) and the bytecode-embedded relative path
    # doesn't exist as an actual file.
    alias_method :rules_ruby_original_open, :open

    def open(path, *args, **kwargs, &block)
      # Normalize relative bytecode paths to absolute paths
      # Handle Pathname objects by converting to string first
      path = path.to_path if path.respond_to?(:to_path)
      if path.is_a?(String) &&
          path.match?(RULES_RUBY_GENERATED_REPO_PREFIX_REGEX)
        path = expand_path(path)
      end

      rules_ruby_original_open(path, *args, **kwargs, &block)
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
      dir = File.dirname(path || "")
      # Expand to absolute path so Zeitwerk and other tools see consistent paths
      File.expand_path(dir)
    end
  end
end

# Patch Zeitwerk classes to normalize bytecode-embedded relative paths.
# This fixes issues where paths like ../rules_ruby++.../gem.rb don't match
# absolute paths Zeitwerk uses when scanning directories.
module Kernel
  alias_method :rules_ruby_original_require, :require

  def require(path)
    result = rules_ruby_original_require(path)

    # After zeitwerk/gem_inflector is loaded, patch it to normalize version_file
    if path.include?("zeitwerk") && defined?(Zeitwerk::GemInflector) &&
        !Zeitwerk::GemInflector.method_defined?(:rules_ruby_patched?)
      Zeitwerk::GemInflector.class_eval do
        def rules_ruby_patched?
          true
        end

        alias_method :rules_ruby_original_initialize, :initialize

        def initialize(root_file)
          # Normalize the root_file path BEFORE calling the original constructor
          # This ensures @version_file is set with an absolute path
          # Use the patched expand_path which handles ../rules_ruby++ prefix
          normalized_root_file = File.expand_path(root_file)
          rules_ruby_original_initialize(normalized_root_file)
        end
      end
    end

    # Patch GemLoader to normalize root_file before initialize
    # This ensures @root_dir is derived from an absolute path, fixing warnings
    # that would otherwise show relative bytecode paths
    if path.include?("zeitwerk") && defined?(Zeitwerk::GemLoader) &&
        !Zeitwerk::GemLoader.method_defined?(:rules_ruby_gem_loader_patched?)
      Zeitwerk::GemLoader.class_eval do
        def rules_ruby_gem_loader_patched?
          true
        end

        class << self
          alias_method :rules_ruby_original___new, :__new

          def __new(root_file, namespace:, warn_on_extra_files:)
            # Normalize root_file to absolute path BEFORE creating the loader
            # This ensures @root_dir (set via File.dirname(root_file)) is
            # absolute
            normalized_root_file = File.expand_path(root_file)
            rules_ruby_original___new(
              normalized_root_file,
              namespace: namespace,
              warn_on_extra_files: warn_on_extra_files
            )
          end
        end
      end
    end

    result
  end
end
