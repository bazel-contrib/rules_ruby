#!/usr/bin/env ruby

require "stringio"

src = ARGV[0]
out = ARGV[1]

iseq = RubyVM::InstructionSequence.compile_file(src)
File.binwrite(out, iseq.to_binary)
