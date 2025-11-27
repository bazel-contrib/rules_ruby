# frozen_string_literal: true

raise 'must provide both srcdir and destdir' unless ARGV.length >= 2

$srcdir, $destdir = *ARGV

def sync_dir(dir)
  full_dir = File.join($srcdir, dir)
  Dir.each_child(full_dir) do |f|
    name = dir == '' ? f : File.join(dir, f)
    srcname = File.join($srcdir, name)
    destname = File.join($destdir, name)
    stat = File.lstat(srcname)

    if stat.symlink?
      if srcname.end_with?('.gemspec') || srcname.include?('extconf.rb')
        File.copy_stream(srcname, destname)
      else
        File.symlink(File.readlink(srcname), destname)
      end
    elsif stat.directory?
      Dir.mkdir(destname)
      sync_dir(name)
    elsif stat.file?
      File.symlink(File.join(Dir.pwd, srcname), destname)
    end
  end
end

Dir.mkdir($destdir)
sync_dir ''
