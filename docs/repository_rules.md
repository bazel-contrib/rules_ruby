<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API for repository rules

<a id="rb_bundle"></a>

## rb_bundle

<pre>
rb_bundle(<a href="#rb_bundle-toolchain">toolchain</a>, <a href="#rb_bundle-kwargs">kwargs</a>)
</pre>

Wraps `rb_bundle_rule()` providing default toolchain name.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="rb_bundle-toolchain"></a>toolchain |  default Ruby toolchain BUILD   |  `"@ruby//:BUILD"` |
| <a id="rb_bundle-kwargs"></a>kwargs |  underlying attrs passed to rb_bundle_rule()   |  none |


<a id="rb_register_toolchains"></a>

## rb_register_toolchains

<pre>
rb_register_toolchains(<a href="#rb_register_toolchains-name">name</a>, <a href="#rb_register_toolchains-version">version</a>, <a href="#rb_register_toolchains-version_file">version_file</a>, <a href="#rb_register_toolchains-msys2_packages">msys2_packages</a>, <a href="#rb_register_toolchains-register">register</a>, <a href="#rb_register_toolchains-kwargs">kwargs</a>)
</pre>

Register a Ruby toolchain and lazily download the Ruby Interpreter.

* _(For MRI on Linux and macOS)_ Installed using [ruby-build](https://github.com/rbenv/ruby-build).
* _(For MRI on Windows)_ Installed using [RubyInstaller](https://rubyinstaller.org).
* _(For JRuby on any OS)_ Downloaded and installed directly from [official website](https://www.jruby.org).
* _(For TruffleRuby on Linux and macOS)_ Installed using [ruby-build](https://github.com/rbenv/ruby-build).
* _(For "system")_ Ruby found on the PATH is used. Please note that builds are not hermetic in this case.

`WORKSPACE`:
```bazel
load("@rules_ruby//ruby:deps.bzl", "rb_register_toolchains")

rb_register_toolchains(
    version = "3.0.6"
)
```

Once registered, you can use the toolchain directly as it provides all the binaries:

```output
$ bazel run @ruby -- -e "puts RUBY_VERSION"
$ bazel run @ruby//:bundle -- update
$ bazel run @ruby//:gem -- install rails
```


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="rb_register_toolchains-name"></a>name |  base name of resulting repositories, by default "rules_ruby"   |  `"ruby"` |
| <a id="rb_register_toolchains-version"></a>version |  a semver version of MRI, or a string like [interpreter type]-[version], or "system"   |  `None` |
| <a id="rb_register_toolchains-version_file"></a>version_file |  .ruby-version or .tool-versions file to read version from   |  `None` |
| <a id="rb_register_toolchains-msys2_packages"></a>msys2_packages |  extra MSYS2 packages to install   |  `["libyaml"]` |
| <a id="rb_register_toolchains-register"></a>register |  whether to register the resulting toolchains, should be False under bzlmod   |  `True` |
| <a id="rb_register_toolchains-kwargs"></a>kwargs |  additional parameters to the downloader for this interpreter type   |  none |


<a id="rb_bundle_fetch"></a>

## rb_bundle_fetch

<pre>
rb_bundle_fetch(<a href="#rb_bundle_fetch-name">name</a>, <a href="#rb_bundle_fetch-srcs">srcs</a>, <a href="#rb_bundle_fetch-bundler_checksums">bundler_checksums</a>, <a href="#rb_bundle_fetch-bundler_remote">bundler_remote</a>, <a href="#rb_bundle_fetch-env">env</a>, <a href="#rb_bundle_fetch-gemfile">gemfile</a>, <a href="#rb_bundle_fetch-gemfile_lock">gemfile_lock</a>,
                <a href="#rb_bundle_fetch-repo_mapping">repo_mapping</a>)
</pre>

Fetches Bundler dependencies to be automatically installed by other targets.

Currently doesn't support installing gems from Git repositories,
see https://github.com/bazel-contrib/rules_ruby/issues/62.

`WORKSPACE`:
```bazel
load("@rules_ruby//ruby:deps.bzl", "rb_bundle_fetch")

rb_bundle_fetch(
    name = "bundle",
    gemfile = "//:Gemfile",
    gemfile_lock = "//:Gemfile.lock",
    srcs = [
        "//:gem.gemspec",
        "//:lib/gem/version.rb",
    ]
)
```

All the installed gems can be accessed using `@bundle` target and additionally
gems binary files can also be used via BUILD rules or directly with `bazel run`:

`BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_test")

package(default_visibility = ["//:__subpackages__"])

rb_test(
    name = "rubocop",
    main = "@bundle//bin:rubocop",
    deps = ["@bundle"],
)
```

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="rb_bundle_fetch-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="rb_bundle_fetch-srcs"></a>srcs |  List of Ruby source files necessary during installation.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="rb_bundle_fetch-bundler_checksums"></a>bundler_checksums |  Custom map from Bundler version to its SHA-256 checksum.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  `{}`  |
| <a id="rb_bundle_fetch-bundler_remote"></a>bundler_remote |  Remote to fetch the bundler gem from.   | String | optional |  `"https://rubygems.org/"`  |
| <a id="rb_bundle_fetch-env"></a>env |  Environment variables to use during installation.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  `{}`  |
| <a id="rb_bundle_fetch-gemfile"></a>gemfile |  Gemfile to install dependencies from.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="rb_bundle_fetch-gemfile_lock"></a>gemfile_lock |  Gemfile.lock to install dependencies from.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="rb_bundle_fetch-repo_mapping"></a>repo_mapping |  In `WORKSPACE` context only: a dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.<br><br>For example, an entry `"@foo": "@bar"` declares that, for any time this repository depends on `@foo` (such as a dependency on `@foo//some:target`, it should actually resolve that dependency within globally-declared `@bar` (`@bar//some:target`).<br><br>This attribute is _not_ supported in `MODULE.bazel` context (when invoking a repository rule inside a module extension's implementation function).   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  |


<a id="rb_bundle_rule"></a>

## rb_bundle_rule

<pre>
rb_bundle_rule(<a href="#rb_bundle_rule-name">name</a>, <a href="#rb_bundle_rule-srcs">srcs</a>, <a href="#rb_bundle_rule-env">env</a>, <a href="#rb_bundle_rule-gemfile">gemfile</a>, <a href="#rb_bundle_rule-repo_mapping">repo_mapping</a>, <a href="#rb_bundle_rule-toolchain">toolchain</a>)
</pre>

(Deprecated) Use `rb_bundle_fetch()` instead.

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
| <a id="rb_bundle_rule-srcs"></a>srcs |  List of Ruby source files used to build the library.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="rb_bundle_rule-env"></a>env |  Environment variables to use during installation.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  `{}`  |
| <a id="rb_bundle_rule-gemfile"></a>gemfile |  Gemfile to install dependencies from.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="rb_bundle_rule-repo_mapping"></a>repo_mapping |  In `WORKSPACE` context only: a dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.<br><br>For example, an entry `"@foo": "@bar"` declares that, for any time this repository depends on `@foo` (such as a dependency on `@foo//some:target`, it should actually resolve that dependency within globally-declared `@bar` (`@bar//some:target`).<br><br>This attribute is _not_ supported in `MODULE.bazel` context (when invoking a repository rule inside a module extension's implementation function).   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional |  |
| <a id="rb_bundle_rule-toolchain"></a>toolchain |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |


