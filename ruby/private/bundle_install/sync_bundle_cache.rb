# frozen_string_literal: true

# Syncs the contents of the source `vendor/cache` directory to a destination
# directory, with special handling for certain files. This is required because
# `bundle install` may try to normalize these files, which doesn't play well
# with Bazel sandboxing (since it makes `vendor/cache` read-only).

def sync_dir(srcdir, destdir, dir = '')
  full_dir = File.join(srcdir, dir)
  Dir.each_child(full_dir) do |f|
    name = dir == '' ? f : File.join(dir, f)
    srcname = File.join(srcdir, name)
    destname = File.join(destdir, name)
    stat = File.lstat(srcname)

    if srcname.end_with?('.gemspec') || srcname.include?('extconf.rb') || stat.file?
      File.copy_stream(srcname, destname)
    elsif stat.symlink?
      if Gem.win_platform?
        # On Windows, creating symlinks requires elevated privileges,
        # so just do a normal copy here instead.
        File.copy_stream(srcname, destname)
      else
        File.symlink(File.readlink(srcname), destname)
      end
    elsif stat.directory?
      Dir.mkdir(destname)
      sync_dir(srcdir, destdir, name)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  raise 'must provide both srcdir and destdir' unless ARGV.length >= 2

  srcdir, destdir = ARGV
  sync_dir(srcdir, destdir)
end
