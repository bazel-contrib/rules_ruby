#!/usr/bin/env ruby
# frozen_string_literal: true

# Bytecode pack file format:
#
# Header (32 bytes):
#   Offset  Size  Description
#   0       4     Magic bytes: "RRBC" (Rules Ruby Bytecode)
#   4       4     Version: uint32 (1)
#   8       8     Index offset: uint64
#   16      8     Index size: uint64
#   24      8     Reserved
#
# Data section:
#   Concatenated bytecode blobs
#
# Index section (Marshal format):
#   { "path" => [offset, length], ... }

class BytecodePacker
  MAGIC = "RRBC"
  VERSION = 1
  HEADER_SIZE = 32

  def initialize(output_path)
    @output_path = output_path
    @entries = {} # path => bytecode_binary
  end

  def add(path, bytecode)
    @entries[path] = bytecode
  end

  def size
    @entries.size
  end

  def write
    File.open(@output_path, "wb") do |f|
      # Write placeholder header
      f.write("\0" * HEADER_SIZE)

      # Write bytecode blobs, track offsets
      index = {}
      @entries.each do |path, bytecode|
        offset = f.pos
        f.write(bytecode)
        index[path] = [offset, bytecode.bytesize]
      end

      # Write index
      index_offset = f.pos
      index_data = Marshal.dump(index)
      f.write(index_data)
      index_size = index_data.bytesize

      # Write header
      f.seek(0)
      f.write(MAGIC)
      f.write([VERSION].pack("L<"))
      f.write([index_offset].pack("Q<"))
      f.write([index_size].pack("Q<"))
      # Reserved bytes already zeroed from placeholder
    end
  end
end
