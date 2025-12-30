#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "pack_reader"

module RulesRuby
  module BytecodeLoader
    class Stats
      attr_accessor :hits, :misses
      attr_accessor :pack_load_time, :total_lookup_time, :total_iseq_load_time

      def initialize(hits = 0, misses = 0)
        @hits = hits
        @misses = misses
        @pack_load_time = 0.0
        @total_lookup_time = 0.0
        @total_iseq_load_time = 0.0
      end

      def total
        @hits + @misses
      end

      def hit_rate
        total = self.total
        return nil if total.zero?

        (hits.to_f / total * 100).round(2)
      end

      def total_bytecode_time
        @total_lookup_time + @total_iseq_load_time
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
        load_pack

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
            [
              "Final stats: #{stats.hits} hits, #{stats.misses} misses (#{stats.hit_rate}% hit rate)",
              "  Pack load time:  #{format_time(stats.pack_load_time)}",
              "  Index lookups:   #{format_time(stats.total_lookup_time)} (#{stats.total} lookups)",
              "  ISeq loads:      #{format_time(stats.total_iseq_load_time)} (#{stats.hits} loads)",
              "  Total bytecode:  #{format_time(stats.total_bytecode_time)}"
            ]
          end
        end
      end

      def format_time(seconds)
        if seconds < 0.001
          "%.3f µs" % (seconds * 1_000_000)
        elsif seconds < 1
          "%.3f ms" % (seconds * 1000)
        else
          "%.3f s" % seconds
        end
      end

      def runfiles_dir
        @runfiles_dir ||= ENV["RUNFILES_DIR"]
      end

      def runfiles_prefix
        @runfiles_prefix ||= "#{runfiles_dir}/"
      end

      def pack_reader
        @pack_reader
      end

      def load(path)
        return nil unless @pack_reader

        # Normalize the path for the lookup.
        path = path.delete_prefix(runfiles_prefix)

        # Time the index lookup
        lookup_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        bytecode = @pack_reader.get(path)
        lookup_end = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        stats.total_lookup_time += (lookup_end - lookup_start)

        debug do
          [
            "-----",
            "Path: #{path}",
            "Pack lookup: #{bytecode ? "found (#{bytecode.bytesize} bytes)" : "not found"}"
          ]
        end

        unless bytecode
          stats.misses += 1
          return nil
        end

        stats.hits += 1

        # Time the ISeq load
        iseq_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result = RubyVM::InstructionSequence.load_from_binary(bytecode)
        iseq_end = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        stats.total_iseq_load_time += (iseq_end - iseq_start)

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

      def load_pack
        pack_path = ENV["RUBY_BYTECODE_PACK"]
        debug { "Pack path: #{pack_path}" }
        return unless pack_path

        unless File.exist?(pack_path)
          error { "Pack file not found: #{pack_path}" }
          return
        end

        load_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @pack_reader = BytecodePackReader.new(pack_path)
        load_end = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        stats.pack_load_time = load_end - load_start

        info { "Loaded pack with #{@pack_reader.size} entries (mmap: #{@pack_reader.instance_variable_get(:@use_mmap)}) in #{format_time(stats.pack_load_time)}" }
      rescue => e
        warn "[RulesRuby::BytecodeLoader] Failed to load pack: #{e.class}: #{e.message}"
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

# Auto-enable if pack is present
if ENV["RUBY_BYTECODE_PACK"]
  RulesRuby::BytecodeLoader.enable!

  # Print statistics at program exit
  at_exit do
    RulesRuby::BytecodeLoader.log_stats
  end
end
