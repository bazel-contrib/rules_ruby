require 'fileutils'
require 'rubygems/package'
require 'tmpdir'

gemspec = File.read('{gemspec}')
gem_file = File.expand_path('{gem_filename}', '{bazel_out_dir}')
srcs = {inputs}

Dir.mktmpdir do |tmpdir|
  srcs.each do |src|
    dst = File.join(tmpdir, src)
    FileUtils.mkdir_p(File.dirname(dst))
    FileUtils.cp(src, dst)
    # https://github.com/bazelbuild/bazel/issues/5588
    File.chmod(0o644, dst)
  end

  Dir.chdir(tmpdir) do
    spec = binding.eval(gemspec, '{gemspec}', __LINE__)
    file = Gem::Package.build(spec)
    FileUtils.mv(file, gem_file)
  end
end

# vim: ft=ruby
