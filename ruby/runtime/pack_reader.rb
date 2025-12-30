#!/usr/bin/env ruby
# frozen_string_literal: true

module RulesRuby
  # Reads bytecode from a packed archive file using memory-mapping.
  #
  # File format:
  #   Header (32 bytes):
  #     0-3:   Magic "RRBC"
  #     4-7:   Version (uint32)
  #     8-15:  Index offset (uint64)
  #     16-23: Index size (uint64)
  #     24-31: Reserved
  #
  #   Data section: Concatenated bytecode blobs
  #   Index section: Marshal-encoded { path => [offset, length] }
  #
  class BytecodePackReader
    MAGIC = "RRBC"
    HEADER_SIZE = 32

    attr_reader :path

    def initialize(path)
      @path = path
      @file = File.open(path, "rb")

      # Use IO::Buffer.map for memory-mapped access (Ruby 3.1+)
      # Falls back to reading the entire file on older Ruby versions
      if defined?(IO::Buffer) && IO::Buffer.respond_to?(:map)
        @buffer = IO::Buffer.map(@file, nil, 0, IO::Buffer::READONLY)
        @use_mmap = true
      else
        @data = File.binread(path)
        @use_mmap = false
      end

      validate_header!
      load_index!
    end

    def get(path)
      entry = @index[path]
      return nil unless entry

      offset, length = entry
      if @use_mmap
        @buffer.get_string(offset, length)
      else
        @data[offset, length]
      end
    end

    def key?(path)
      @index.key?(path)
    end

    def keys
      @index.keys
    end

    def size
      @index.size
    end

    def close
      @buffer = nil
      @data = nil
      @file&.close
      @file = nil
    end

    def each
      return enum_for(:each) unless block_given?

      @index.each do |path, (offset, length)|
        bytecode = if @use_mmap
          @buffer.get_string(offset, length)
        else
          @data[offset, length]
        end
        yield path, bytecode
      end
    end

    private

    def validate_header!
      magic = read_bytes(0, 4)
      raise "Invalid magic: #{magic.inspect}, expected #{MAGIC.inspect}" unless magic == MAGIC

      version = read_uint32(4)
      raise "Unsupported version: #{version}" unless version == 1
    end

    def load_index!
      index_offset = read_uint64(8)
      index_size = read_uint64(16)

      index_data = read_bytes(index_offset, index_size)
      @index = Marshal.load(index_data)
    end

    def read_bytes(offset, length)
      if @use_mmap
        @buffer.get_string(offset, length)
      else
        @data[offset, length]
      end
    end

    def read_uint32(offset)
      read_bytes(offset, 4).unpack1("L<")
    end

    def read_uint64(offset)
      read_bytes(offset, 8).unpack1("Q<")
    end
  end
end
