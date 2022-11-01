require 'fileutils'
require 'json'
require 'rubygems/package'
require 'tmpdir'

gemspec_path = '{gemspec}'
packaged_gem_path = File.expand_path('{gem_filename}', '{bazel_out_dir}')
inputs = JSON.parse('{inputs_manifest}')

Dir.mktmpdir do |tmpdir|
  inputs.each do |src, dst|
    dst = File.join(tmpdir, dst)
    FileUtils.mkdir_p(File.dirname(dst))
    FileUtils.cp(src, dst)
    # https://github.com/bazelbuild/bazel/issues/5588
    File.chmod(0o644, dst)
  end

  Dir.chdir(tmpdir) do
    gemspec_dir = File.dirname(gemspec_path)
    gemspec_file = File.basename(gemspec_path)
    gemspec_code = File.read(gemspec_path)

    Dir.chdir(gemspec_dir) do
      spec = binding.eval(gemspec_code, gemspec_file, __LINE__)
      file = Gem::Package.build(spec)
      FileUtils.mv(file, packaged_gem_path)
    end
  end
end

# vim: ft=ruby
