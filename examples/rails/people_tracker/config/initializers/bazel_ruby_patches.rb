# frozen_string_literal: true

# Bazel Ruby patches for Rails tests
#
# These patches fix issues with require_relative and __dir__ in Bazel's
# sandboxed environment. Without these patches, require_relative bypasses
# the sandbox by reading files directly from the source tree instead of
# the runfiles tree.
#
# See: https://github.com/bazel-contrib/rules_ruby/issues/225

module Kernel
  unless respond_to?(:bazel_ruby_patches_applied?)
    def bazel_ruby_patches_applied?
      true
    end

    alias_method :brp_original_require_relative, :require_relative
    alias_method :brp_original___dir__, :__dir__

    def require_relative(path)
      base = caller_locations(1..1).first&.path
      base = "" if base.nil?
      base_directory = File.dirname(base)
      require File.expand_path(path, base_directory)
    end

    def __dir__
      File.dirname(caller_locations(1..1).first&.path)
    end
  end
end
