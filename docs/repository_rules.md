<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="rb_bundle"></a>

## rb_bundle

<pre>
rb_bundle(<a href="#rb_bundle-name">name</a>, <a href="#rb_bundle-gemfile">gemfile</a>, <a href="#rb_bundle-repo_mapping">repo_mapping</a>, <a href="#rb_bundle-srcs">srcs</a>)
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
| <a id="rb_bundle-name"></a>name |  A unique name for this repository.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="rb_bundle-gemfile"></a>gemfile |  Gemfile to install dependencies from.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="rb_bundle-repo_mapping"></a>repo_mapping |  A dictionary from local repository name to global repository name. This allows controls over workspace dependency resolution for dependencies of this repository.&lt;p&gt;For example, an entry <code>"@foo": "@bar"</code> declares that, for any time this repository depends on <code>@foo</code> (such as a dependency on <code>@foo//some:target</code>, it should actually resolve that dependency within globally-declared <code>@bar</code> (<code>@bar//some:target</code>).   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | required |  |
| <a id="rb_bundle-srcs"></a>srcs |  List of Ruby source files used to build the library.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |


<a id="rb_download"></a>

## rb_download

<pre>
rb_download(<a href="#rb_download-version">version</a>, <a href="#rb_download-kwargs">kwargs</a>)
</pre>

    Register a Ruby toolchain and lazily download the Ruby Interpreter.

* _(For MRI on Linux and macOS)_ Installed using [ruby-build](https://github.com/rbenv/ruby-build).
* _(For MRI on Windows)_ Installed using [RubyInstaller](https://rubyinstaller.org).
* _(For JRuby on any OS)_ Downloaded and installed directly from [official website](https://www.jruby.org).
* _(For TruffleRuby on Linux and macOS)_ Installed using [ruby-build](https://github.com/rbenv/ruby-build).

`WORKSPACE`:
```bazel
load("@rules_ruby//ruby:deps.bzl", "rb_download")

rb_download(
    version = "2.7.5"
)
```

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="rb_download-version"></a>version |  <p align="center"> - </p>   |  <code>None</code> |
| <a id="rb_download-kwargs"></a>kwargs |  <p align="center"> - </p>   |  none |


<a id="rb_register_toolchains"></a>

## rb_register_toolchains

<pre>
rb_register_toolchains(<a href="#rb_register_toolchains-version">version</a>, <a href="#rb_register_toolchains-kwargs">kwargs</a>)
</pre>

    Register a Ruby toolchain and lazily download the Ruby Interpreter.

* _(For MRI on Linux and macOS)_ Installed using [ruby-build](https://github.com/rbenv/ruby-build).
* _(For MRI on Windows)_ Installed using [RubyInstaller](https://rubyinstaller.org).
* _(For JRuby on any OS)_ Downloaded and installed directly from [official website](https://www.jruby.org).
* _(For TruffleRuby on Linux and macOS)_ Installed using [ruby-build](https://github.com/rbenv/ruby-build).

`WORKSPACE`:
```bazel
load("@rules_ruby//ruby:deps.bzl", "rb_download")

rb_download(
    version = "2.7.5"
)
```

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="rb_register_toolchains-version"></a>version |  <p align="center"> - </p>   |  <code>None</code> |
| <a id="rb_register_toolchains-kwargs"></a>kwargs |  <p align="center"> - </p>   |  none |


