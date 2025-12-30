#!/usr/bin/env ruby
# frozen_string_literal: true

# Merge multiple bytecode pack files into a single output pack.
#
# Usage: merge_packs.rb <output_pack> <input_pack1> [input_pack2] ...
#
# This script reads bytecode entries from one or more input pack files
# and writes them to a single merged output pack. Later packs take
# precedence for duplicate paths.

class BytecodePacker
  MAGIC = "RRBC"
  VERSION = 1
  HEADER_SIZE = 32

  def initialize(output_path)
    @output_path = output_path
    @entries = {}
  end

  def add(path, bytecode)
    @entries[path] = bytecode
  end

  def size
    @entries.size
  end

  def write
    File.open(@output_path, "wb") do |f|
      f.write("\0" * HEADER_SIZE)
      index = {}
      @entries.each do |path, bytecode|
        offset = f.pos
        f.write(bytecode)
        index[path] = [offset, bytecode.bytesize]
      end
      index_offset = f.pos
      index_data = Marshal.dump(index)
      f.write(index_data)
      index_size = index_data.bytesize
      f.seek(0)
      f.write(MAGIC)
      f.write([VERSION].pack("L<"))
      f.write([index_offset].pack("Q<"))
      f.write([index_size].pack("Q<"))
    end
  end
end

class BytecodePackReader
  MAGIC = "RRBC"
  HEADER_SIZE = 32

  def initialize(path)
    @path = path
    @data = File.binread(path)
    validate_header!
    load_index!
  end

  def each
    return enum_for(:each) unless block_given?

    @index.each do |path, (offset, length)|
      yield path, @data[offset, length]
    end
  end

  private

  def validate_header!
    magic = @data[0, 4]
    raise "Invalid magic: #{magic.inspect}" unless magic == MAGIC

    version = @data[4, 4].unpack1("L<")
    raise "Unsupported version: #{version}" unless version == 1
  end

  def load_index!
    index_offset = @data[8, 8].unpack1("Q<")
    index_size = @data[16, 8].unpack1("Q<")
    index_data = @data[index_offset, index_size]
    @index = Marshal.load(index_data)
  end
end

class PackMerger
  def initialize(output_path)
    @packer = BytecodePacker.new(output_path)
  end

  def add_pack(pack_path)
    return unless File.exist?(pack_path)

    reader = BytecodePackReader.new(pack_path)
    reader.each do |path, bytecode|
      @packer.add(path, bytecode)
    end
  end

  def write
    @packer.write
  end

  def size
    @packer.size
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.size < 2
    warn "Usage: merge_packs.rb <output_pack> <input_pack1> [input_pack2] ..."
    exit 1
  end

  output_path = ARGV[0]
  input_packs = ARGV[1..]

  merger = PackMerger.new(output_path)

  input_packs.each do |pack_path|
    if File.exist?(pack_path)
      merger.add_pack(pack_path)
      warn "[merge_packs.rb] Added pack: #{pack_path}"
    else
      warn "[merge_packs.rb] Skipping missing pack: #{pack_path}"
    end
  end

  merger.write
  warn "[merge_packs.rb] Merged #{merger.size} entries to #{output_path}"
end
