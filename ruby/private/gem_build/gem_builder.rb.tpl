# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'rubygems/package'
require 'tmpdir'

gemspec_path = '{gemspec}'
packaged_gem_path = File.expand_path('{gem_filename}', '{bazel_out_dir}')
inputs = JSON.parse('{inputs_manifest}')

# We need to check if there are inputs which are directories.
# For such cases, we are going to check the contents of the directories
# and add the file to the inputs manifest.
inputs.dup.each do |src, dst|
  next unless File.directory?(src)

  inputs.delete(src)
  Dir.chdir(src) do
    Dir['**/*'].each do |file|
      inputs[File.join(src, file)] = File.join(dst, file)
    end
  end
end

Dir.mktmpdir do |tmpdir|
  inputs.each do |src, dst|
    dst = File.join(tmpdir, dst)
    FileUtils.mkdir_p(File.dirname(dst))
    FileUtils.cp(src, dst)
  end

  Dir.chdir(tmpdir) do
    gemspec_dir = File.dirname(gemspec_path)
    gemspec_file = File.basename(gemspec_path)
    gemspec_code = File.read(gemspec_path)

    Dir.chdir(gemspec_dir) do
      spec = binding.eval(gemspec_code, gemspec_file, __LINE__) # rubocop:disable Security/Eval
      file = Gem::Package.build(spec)
      FileUtils.mv(file, packaged_gem_path)
    end
  end
end

# vim: ft=ruby
