# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'bazel/runfiles'

class ManifestBasedTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @manifest = File.join(@dir, 'MANIFEST')
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def strategy(contents)
    File.write(@manifest, contents)
    Bazel::Runfiles::ManifestBased.new(@manifest)
  end

  def test_exact_match
    r = strategy("_main/pkg/file.txt /abs/pkg/file.txt\n")
    assert_equal '/abs/pkg/file.txt', r.rlocation('_main/pkg/file.txt')
  end

  def test_prefix_walk
    r = strategy("_main/pkg /abs/pkg\n")
    assert_equal '/abs/pkg/sub/file.txt', r.rlocation('_main/pkg/sub/file.txt')
  end

  def test_missing_path_returns_nil
    r = strategy("_main/pkg/file.txt /abs/pkg/file.txt\n")
    assert_nil r.rlocation('_main/pkg/other.txt')
  end

  def test_empty_file_convention
    r = strategy("_main/empty.txt\n")
    assert_equal '', r.rlocation('_main/empty.txt')
  end

  def test_escaped_path_with_spaces
    r = strategy(" _main/dir\\swith\\sspaces/file.txt /abs/dir\\swith\\sspaces/file.txt\n")
    assert_equal '/abs/dir with spaces/file.txt', r.rlocation('_main/dir with spaces/file.txt')
  end

  def test_escaped_path_with_backslash_and_newline
    r = strategy(" _main/a\\bs\\nb /abs/a\\bs\\nb\n")
    assert_equal "/abs/a\\s\nb", r.rlocation("_main/a\\s\nb")
  end

  def test_escaped_empty_file
    r = strategy(" _main/weird\\spath\n")
    assert_equal '', r.rlocation('_main/weird path')
  end

  def test_prefix_with_empty_value_not_matched_as_directory
    r = strategy("_main/empty.txt \n_main/empty.txt/child.rb /abs/child.rb\n")
    assert_equal '/abs/child.rb', r.rlocation('_main/empty.txt/child.rb')
  end
end

class DirectoryBasedTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def test_rlocation_joins_dir_and_path
    r = Bazel::Runfiles::DirectoryBased.new(@dir)
    assert_equal File.join(@dir, '_main/pkg/file.txt'), r.rlocation('_main/pkg/file.txt')
  end

  def test_rlocation_returns_nil_when_no_dir
    r = Bazel::Runfiles::DirectoryBased.new('')
    assert_nil r.rlocation('_main/pkg/file.txt')
  end
end

class RunfilesTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @manifest = File.join(@dir, 'MANIFEST')
    File.write(@manifest, "_main/a.txt /abs/a.txt\n")
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def directory_runfiles(dir = @dir)
    Bazel::Runfiles.new(Bazel::Runfiles::DirectoryBased.new(dir))
  end

  def test_empty_path_raises
    assert_raises(ArgumentError) { directory_runfiles.rlocation('') }
  end

  def test_nil_path_raises
    assert_raises(ArgumentError) { directory_runfiles.rlocation(nil) }
  end

  def test_absolute_path_returned_unchanged
    assert_equal '/already/absolute.txt', directory_runfiles.rlocation('/already/absolute.txt')
  end

  def test_non_normalized_paths_raise
    ['../foo', 'foo/../bar', './foo', 'foo/./bar', 'foo/.', 'foo//bar'].each do |path|
      assert_raises(ArgumentError, "expected #{path.inspect} to raise") do
        directory_runfiles.rlocation(path)
      end
    end
  end

  def test_absolute_without_drive_letter_raises
    assert_raises(ArgumentError) { directory_runfiles.rlocation('\\foo') }
  end

  def test_create_picks_manifest_mode_when_manifest_file_set
    r = Bazel::Runfiles.create('RUNFILES_MANIFEST_FILE' => @manifest)
    assert_equal '/abs/a.txt', r.rlocation('_main/a.txt')
  end

  def test_create_picks_directory_mode_when_dir_set
    r = Bazel::Runfiles.create('RUNFILES_DIR' => @dir)
    assert_equal File.join(@dir, '_main/a.txt'), r.rlocation('_main/a.txt')
  end

  def test_create_prefers_manifest_over_directory
    r = Bazel::Runfiles.create(
      'RUNFILES_MANIFEST_FILE' => @manifest,
      'RUNFILES_DIR' => @dir
    )
    assert_equal '/abs/a.txt', r.rlocation('_main/a.txt')
  end
end
