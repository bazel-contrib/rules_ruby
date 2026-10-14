# frozen_string_literal: true

# Rewrites the versions of path gems in a Gemfile.lock to match their gemspecs,
# so a gemspec whose version is generated at build time still passes Bundler's
# deployment-mode check without the checked-in lock having to agree with it.

source_lock, gemfile, output_lock = ARGV
lock = File.binread(source_lock)
crlf = lock.include?("\r\n")
lock = lock.gsub("\r\n", "\n")
gemfile_dir = File.dirname(File.expand_path(gemfile))

# Matches Bundler::Source::Path#to_lock, including its default glob.
path_source = /^PATH\n  remote: (.+)\n(?:  glob: (.+)\n)?  specs:\n((?:    .+\n)+)/
default_glob = '{,*,*/*}.gemspec'

versions = {}
lock.scan(path_source) do |remote, glob, specs|
  dir = File.expand_path(remote, gemfile_dir)
  gemspecs = Dir.glob(glob || default_glob, base: dir).to_h do |file|
    path = File.join(dir, file)
    spec = Dir.chdir(File.dirname(path)) { Gem::Specification.load(path) } or abort "Cannot load #{path}"
    [spec.name, spec]
  end
  specs.scan(/^    (\S+) \(([^)]+)\)$/) do |name, locked|
    next unless gemspecs.key?(name)

    versions[name] = [locked.split('-', 2).first, gemspecs[name].version.to_s]
  end
end

versions.each do |name, (locked, actual)|
  lock = lock.gsub(/^(  |    )#{Regexp.escape(name)} \(#{Regexp.escape(locked)}(-[^)]*)?\)/) do
    "#{Regexp.last_match(1)}#{name} (#{actual}#{Regexp.last_match(2)})"
  end
end

lock = lock.gsub("\n", "\r\n") if crlf
File.binwrite(output_lock, lock)
