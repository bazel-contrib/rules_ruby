<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API for repository rules

<a id="rb_bundle_rule"></a>

## rb_bundle_rule

<pre>
rb_bundle_rule(<a href="#rb_bundle_rule-name">name</a>, <a href="#rb_bundle_rule-env">env</a>, <a href="#rb_bundle_rule-gemfile">gemfile</a>, <a href="#rb_bundle_rule-repo_mapping">repo_mapping</a>, <a href="#rb_bundle_rule-srcs">srcs</a>, <a href="#rb_bundle_rule-toolchain">toolchain</a>)
</pre>


Installs Bundler dependencies and registers an external repository
that can be used by other targets.

`WORKSPACE`:
```bazel
load("@rules_ruby//ruby:deps.bzl", "rb_bundle")

rb_bundle(
    name = "bundle",
    gemfile = "//:Gemfile",
    srcs = [
        "//:gem.gemspec",
        "//:lib/gem/version.rb",
    ]
)
```

All the installed gems can be accessed using `@bundle` target and additionally
gems binary files can also be used:

`BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_binary")

package(default_visibility = ["//:__subpackages__"])

rb_binary(
    name = "rubocop",
    main = "@bundle//:bin/rubocop",
    deps = ["@bundle"],
)
```
    

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="rb_bundle_rule-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="rb_bundle_rule-env"></a>env |  Environment variables to use during installation.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional | <code>{}</code> |
| <a id="rb_bundle_rule-gemfile"></a>gemfile |  Gemfile to install dependencies from.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="rb_bundle_rule-repo_mapping"></a>repo_mapping |  A dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.&lt;p&gt;For example, an entry <code>"@foo": "@bar"</code> declares that, for any time this repository depends on <code>@foo</code> (such as a dependency on <code>@foo//some:target</code>, it should actually resolve that dependency within globally-declared <code>@bar</code> (<code>@bar//some:target</code>).   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | required |  |
| <a id="rb_bundle_rule-srcs"></a>srcs |  List of Ruby source files used to build the library.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="rb_bundle_rule-toolchain"></a>toolchain |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


<a id="rb_bundle"></a>

## rb_bundle

<pre>
rb_bundle(<a href="#rb_bundle-toolchain">toolchain</a>, <a href="#rb_bundle-kwargs">kwargs</a>)
</pre>

    Wraps `rb_bundle_rule()` providing default toolchain name.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="rb_bundle-toolchain"></a>toolchain |  default Ruby toolchain BUILD   |  <code>"@ruby//:BUILD"</code> |
| <a id="rb_bundle-kwargs"></a>kwargs |  underlying attrs passed to rb_bundle_rule()   |  none |


<a id="rb_register_toolchains"></a>

## rb_register_toolchains

<pre>
rb_register_toolchains(<a href="#rb_register_toolchains-name">name</a>, <a href="#rb_register_toolchains-version">version</a>, <a href="#rb_register_toolchains-version_file">version_file</a>, <a href="#rb_register_toolchains-register">register</a>, <a href="#rb_register_toolchains-kwargs">kwargs</a>)
</pre>

    Register a Ruby toolchain and lazily download the Ruby Interpreter.

* _(For MRI on Linux and macOS)_ Installed using [ruby-build](https://github.com/rbenv/ruby-build).
* _(For MRI on Windows)_ Installed using [RubyInstaller](https://rubyinstaller.org).
* _(For JRuby on any OS)_ Downloaded and installed directly from [official website](https://www.jruby.org).
* _(For TruffleRuby on Linux and macOS)_ Installed using [ruby-build](https://github.com/rbenv/ruby-build).
* _(For "system") Ruby found on the PATH is used. Please note that builds are not hermetic in this case.

`WORKSPACE`:
```bazel
load("@rules_ruby//ruby:deps.bzl", "rb_register_toolchains")

rb_register_toolchains(
    version = "3.0.6"
)
```


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="rb_register_toolchains-name"></a>name |  base name of resulting repositories, by default "rules_ruby"   |  <code>"ruby"</code> |
| <a id="rb_register_toolchains-version"></a>version |  a semver version of MRI, or a string like [interpreter type]-[version], or "system"   |  <code>None</code> |
| <a id="rb_register_toolchains-version_file"></a>version_file |  .ruby-version or .tool-versions file to read version from   |  <code>None</code> |
| <a id="rb_register_toolchains-register"></a>register |  whether to register the resulting toolchains, should be False under bzlmod   |  <code>True</code> |
| <a id="rb_register_toolchains-kwargs"></a>kwargs |  additional parameters to the downloader for this interpreter type   |  none |


