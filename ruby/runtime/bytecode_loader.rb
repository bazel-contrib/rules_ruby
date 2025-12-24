#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

module RulesRuby
  module BytecodeLoader
    class Stats
      attr_accessor :hits, :misses

      def initialize(hits = 0, misses = 0)
        @hits = hits
        @misses = misses
      end

      def total
        @hits + @misses
      end

      def hit_rate
        total = self.total
        return nil if total.zero?

        (hits.to_f / total * 100).round(2)
      end
    end

    class << self
      ALL_LOG_LEVELS = [:debug, :info, :error].freeze

      def stats
        @stats ||= Stats.new
      end

      def enable!
        return if @enabled

        @enabled = true
        setup_logging
        load_manifest

        RubyVM::InstructionSequence.singleton_class.prepend(
          InstructionSequenceMixin
        )
      end

      def disable!
        @enabled = false
      end

      def enabled?
        @enabled ||= false
      end

      def debug(&block)
        log(:debug, &block)
      end

      def info(&block)
        log(:info, &block)
      end

      def error(&block)
        log(:error, &block)
      end

      def log(log_level)
        return unless @log_levels&.include?(log_level)

        msgs = yield
        Array(msgs).each do |msg|
          warn "[RulesRuby::BytecodeLoader] #{msg}"
        end
      end

      def log_stats
        if stats.total.zero?
          info { "No bytecode was loaded." }
        else
          info do
            "Final stats: #{stats.hits} hits, #{stats.misses} misses " \
              "(#{stats.hit_rate}% hit rate)"
          end
        end
      end

      def runfiles_dir
        @runfiles_dir ||= ENV["RUNFILES_DIR"]
      end

      def runfiles_prefix
        @runfiles_prefix ||= "#{runfiles_dir}/"
      end

      def manifest
        @manifest ||= {}
      end

      def load(path)
        # Normalize the path for the lookup.
        path = path.delete_prefix(runfiles_prefix)

        # Look up bytecode path in manifest
        bytecode_runfiles_path = manifest[path]

        debug do
          [
            "-----",
            "Path: #{path}",
            "Manifest lookup: #{bytecode_runfiles_path || "not found"}"
          ]
        end

        unless bytecode_runfiles_path
          stats.misses += 1
          debug { "No bytecode in manifest, returning nil" }
          return nil
        end

        # Resolve bytecode path using runfiles
        unless runfiles_dir
          stats.misses += 1
          debug { "RUNFILES_DIR not set, returning nil" }
          return nil
        end

        bytecode_path = File.join(runfiles_dir, bytecode_runfiles_path)

        unless File.exist?(bytecode_path)
          stats.misses += 1
          debug { "Bytecode file not found at #{bytecode_path}, returning nil" }
          return nil
        end

        stats.hits += 1
        result = RubyVM::InstructionSequence.load_from_binary(
          File.binread(bytecode_path)
        )
        debug { "Successfully loaded bytecode: #{result.class}" }

        result
      rescue RuntimeError => e
        if e.message == "broken binary format"
          error { "Warning: broken bytecode for #{path}" }
          nil
        else
          error { "Unexpected error: #{e.class}: #{e.message}" }
          raise
        end
      rescue => e
        error { "Unexpected error: #{e.class}: #{e.message}" }
        warn e.backtrace.first(5).join("\n")
        raise
      end

      private

      def setup_logging
        @log_level = (ENV["RUBY_BYTECODE_LOADER_LOG_LEVEL"] || "error").to_sym
        log_level_idx = ALL_LOG_LEVELS.index(@log_level) ||
          ALL_LOG_LEVELS.index(:error)
        @log_levels = ALL_LOG_LEVELS[log_level_idx..]
      end

      def load_manifest
        manifest_path = ENV["RUBY_BYTECODE_MANIFEST"]
        debug { "Manifest path: #{manifest_path}" }
        return unless manifest_path

        unless File.exist?(manifest_path)
          error { "Manifest file not found: #{manifest_path}" }
          return
        end

        manifest_data = JSON.parse(File.read(manifest_path))
        @manifest = manifest_data["entries"] || {}

        info { "Loaded manifest with #{@manifest.size} entries" }
      rescue => e
        warn "[RulesRuby::BytecodeLoader] Failed to load manifest: #{e.class}: \
        #{e.message}"
      end
    end

    module InstructionSequenceMixin
      def load_iseq(path)
        return nil unless RulesRuby::BytecodeLoader.enabled?
        return nil if defined?(Coverage) && Coverage.running?

        RulesRuby::BytecodeLoader.load(path)
      end
    end
  end
end

# Auto-enable if manifest is present
if ENV["RUBY_BYTECODE_MANIFEST"]
  # DEBUG BEGIN
  ENV["RUBY_BYTECODE_LOADER_LOG_LEVEL"] = "debug"
  # DEBUG END
  RulesRuby::BytecodeLoader.enable!

  # Print statistics at program exit
  at_exit do
    RulesRuby::BytecodeLoader.log_stats
  end
end
