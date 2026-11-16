# frozen_string_literal: true

if ENV['COVERAGE'] == '1'
  begin
    require 'bundler/setup'
    require 'simplecov'
    require 'simplecov-lcov'

    SimpleCov::Formatter::LcovFormatter.config do |config|
      config.report_with_single_file = true
      config.single_report_path = ENV['COVERAGE_OUTPUT_FILE']
    end

    SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter
    SimpleCov.command_name ENV['BAZEL_TARGET'] if ENV['BAZEL_TARGET']

    SimpleCov.start do
      if RUBY_ENGINE == 'jruby'
        # JRuby resolves files to their absolute realpaths (outside the sandbox).
        # We must set root to match these realpaths.
        src_file = ENV['COVERAGE_SRC_FILE']
        src_file_real_path = File.realpath(File.join(Dir.pwd, src_file))
        workspace_root = src_file_real_path.delete_suffix(src_file)
        root workspace_root
        # Redirect output to writable sandbox.
        coverage_dir Dir.pwd
      else
        # MRI preserves the loaded paths (the symlinks in the sandbox).
        # We must set root to the sandbox root.
        root Dir.pwd
      end

      add_filter '/external/'
      add_filter '/spec/'
      add_filter '/test/'

      if ENV['COVERAGE_FILTERS']
        ENV['COVERAGE_FILTERS'].split(',').each do |filter|
          add_filter filter.strip
        end
      end
    end
  rescue LoadError => e
    warn "Coverage enabled but simplecov or simplecov-lcov gems not found: #{e.message}"
  end
end
