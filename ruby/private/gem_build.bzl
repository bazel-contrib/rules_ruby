"Implementation details for rb_gem_build"

load("//ruby/private:library.bzl", LIBRARY_ATTRS = "ATTRS")
load(
    "//ruby/private:providers.bzl",
    "BundlerInfo",
    "RubyFilesInfo",
    "get_bundle_env",
    "get_transitive_data",
    "get_transitive_deps",
    "get_transitive_srcs",
)
load("//ruby/private:utils.bzl", _is_windows = "is_windows")

def _rb_gem_build_impl(ctx):
    tools = depset([])

    gem_builder = ctx.actions.declare_file("{}_gem_builder.rb".format(ctx.label.name))
    transitive_data = get_transitive_data(ctx.files.data, ctx.attr.deps).to_list()
    transitive_deps = get_transitive_deps(ctx.attr.deps).to_list()
    transitive_srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps).to_list()
    bundle_env = get_bundle_env({}, ctx.attr.deps)
    java_toolchain = ctx.toolchains["@bazel_tools//tools/jdk:runtime_toolchain_type"]
    ruby_toolchain = ctx.toolchains["@rules_ruby//ruby:toolchain_type"]

    env = {}
    env.update(ruby_toolchain.env)

    if ruby_toolchain.version.startswith("jruby"):
        env["JAVA_HOME"] = java_toolchain.java_runtime.java_home
        tools = java_toolchain.java_runtime.files
        if _is_windows(ctx):
            env["PATH"] = ruby_toolchain.ruby.dirname

    # Inputs manifest is a dictionary where:
    #   - key is a path where a file is available (https://bazel.build/rules/lib/File#path)
    #   - value is a path where a file should be (https://bazel.build/rules/lib/File#short_path)
    # They are the same for source inputs, but different for generated ones.
    # We need to make sure that gem builder script copies both correctly, e.g.:
    #   {
    #     "rb/Gemfile": "rb/Gemfile",
    #     "bazel-out/darwin_arm64-fastbuild/bin/rb/LICENSE": "rb/LICENSE",
    #   }
    inputs = transitive_data + transitive_srcs + [gem_builder] + [ctx.file.gemspec]
    inputs_manifest = {}
    for src in inputs:
        inputs_manifest[src.path] = src.short_path

    ctx.actions.expand_template(
        template = ctx.file._gem_builder_tpl,
        output = gem_builder,
        substitutions = {
            "{bazel_out_dir}": ctx.outputs.gem.dirname,
            "{gem_filename}": ctx.outputs.gem.basename,
            "{gemspec}": ctx.file.gemspec.path,
            "{inputs_manifest}": json.encode(inputs_manifest),
        },
    )

    args = ctx.actions.args()
    args.add(gem_builder)
    ctx.actions.run(
        executable = ruby_toolchain.ruby,
        inputs = depset(inputs),
        outputs = [ctx.outputs.gem],
        arguments = [args],
        env = env,
        mnemonic = "GemBuild",
        tools = tools,
        use_default_shell_env = not _is_windows(ctx),
    )

    providers = []
    runfiles = ctx.runfiles(transitive_srcs + transitive_data)
    for dep in transitive_deps:
        if BundlerInfo in dep:
            providers.append(dep[BundlerInfo])
            runfiles.merge(ctx.runfiles([dep[BundlerInfo].gemfile, dep[BundlerInfo].path]))
            break

    providers.extend([
        DefaultInfo(
            files = depset([ctx.outputs.gem]),
            runfiles = runfiles,
        ),
        RubyFilesInfo(
            binary = None,
            transitive_data = depset(transitive_data),
            transitive_deps = depset(transitive_deps),
            transitive_srcs = depset(transitive_srcs),
            bundle_env = bundle_env,
        ),
    ])

    return providers

rb_gem_build = rule(
    _rb_gem_build_impl,
    attrs = dict(
        LIBRARY_ATTRS,
        gemspec = attr.label(
            allow_single_file = [".gemspec"],
            mandatory = True,
            doc = "Gemspec file to use for gem building.",
        ),
        _gem_builder_tpl = attr.label(
            allow_single_file = True,
            default = "@rules_ruby//ruby/private/gem_build:gem_builder.rb.tpl",
        ),
        _windows_constraint = attr.label(
            default = "@platforms//os:windows",
        ),
    ),
    outputs = {
        "gem": "%{name}.gem",
    },
    toolchains = [
        "@rules_ruby//ruby:toolchain_type",
        "@bazel_tools//tools/jdk:runtime_toolchain_type",
    ],
    doc = """
Builds a Ruby gem.

Suppose you have the following Ruby gem, where `rb_library()` is used
in `BUILD` files to define the packages for the gem.

```output
|-- BUILD
|-- Gemfile
|-- WORKSPACE
|-- gem.gemspec
`-- lib
    |-- BUILD
    |-- gem
    |   |-- BUILD
    |   |-- add.rb
    |   |-- subtract.rb
    |   `-- version.rb
    `-- gem.rb
```

And a RubyGem specification is:

`gem.gemspec`:
```ruby
root = File.expand_path(__dir__)
$LOAD_PATH.push(File.expand_path('lib', root))
require 'gem/version'

Gem::Specification.new do |s|
  s.name = 'example'
  s.version = GEM::VERSION

  s.authors = ['Foo Bar']
  s.email = ['foobar@gmail.com']
  s.homepage = 'http://rubygems.org'
  s.license = 'MIT'

  s.summary = 'Example'
  s.description = 'Example gem'
  s.files = ['Gemfile'] + Dir['lib/**/*']

  s.require_paths = ['lib']
  s.add_dependency 'rake', '~> 10'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rubocop', '~> 1.10'
end
```

You can now package everything into a `.gem` file by defining a target:

`BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_gem_build")

package(default_visibility = ["//:__subpackages__"])

rb_gem_build(
    name = "gem-build",
    gemspec = "gem.gemspec",
    deps = [
        "//lib:gem",
        "@bundle",
    ],
)
```

```output
$ bazel build :gem-build
INFO: Analyzed target //:gem-build (0 packages loaded, 0 targets configured).
INFO: Found 1 target...
INFO: From Action gem-build.gem:
  Successfully built RubyGem
  Name: example
  Version: 0.1.0
  File: example-0.1.0.gem
Target //:gem-build up-to-date:
  bazel-bin/gem-build.gem
INFO: Elapsed time: 0.196s, Critical Path: 0.10s
INFO: 2 processes: 1 internal, 1 darwin-sandbox.
INFO: Build completed successfully, 2 total actions
```
    """,
)
