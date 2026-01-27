# frozen_string_literal: true
require 'fileutils'

raise 'must provide both srcdir and destdir' unless ARGV.length >= 2

$srcdir, $destdir = *ARGV

def sync_dir(dir)
  full_dir = File.join($srcdir, dir)
  Dir.each_child(full_dir) do |f|
    name = dir == '' ? f : File.join(dir, f)
    srcname = File.join($srcdir, name)
    destname = File.join($destdir, name)
    stat = File.lstat(srcname)

    if srcname.end_with?('.gemspec') || srcname.include?('extconf.rb') || stat.file?
      File.copy_stream(srcname, destname)
    elsif stat.symlink?
      # On Windows, creating symlinks requires elevated privileges,
      # so copy the target file instead. copy_stream follows symlinks.
      File.copy_stream(srcname, destname)
    elsif stat.directory?
      Dir.mkdir(destname)
      sync_dir(name)
    end
  end
end

sync_dir ''
