<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API for repository rules

<a id="rb_bundle"></a>

## rb_bundle

<pre>
rb_bundle(<a href="#rb_bundle-toolchain">toolchain</a>, <a href="#rb_bundle-kwargs">kwargs</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="rb_bundle-toolchain"></a>toolchain |  <p align="center"> - </p>   |  <code>"@rules_ruby_dist//:BUILD"</code> |
| <a id="rb_bundle-kwargs"></a>kwargs |  <p align="center"> - </p>   |  none |


<a id="rb_register_toolchains"></a>

## rb_register_toolchains

<pre>
rb_register_toolchains(<a href="#rb_register_toolchains-name">name</a>, <a href="#rb_register_toolchains-version">version</a>, <a href="#rb_register_toolchains-register">register</a>, <a href="#rb_register_toolchains-kwargs">kwargs</a>)
</pre>

    Register a Ruby toolchain and lazily download the Ruby Interpreter.

* _(For MRI on Linux and macOS)_ Installed using [ruby-build](https://github.com/rbenv/ruby-build).
* _(For MRI on Windows)_ Installed using [RubyInstaller](https://rubyinstaller.org).
* _(For JRuby on any OS)_ Downloaded and installed directly from [official website](https://www.jruby.org).
* _(For TruffleRuby on Linux and macOS)_ Installed using [ruby-build](https://github.com/rbenv/ruby-build).

`WORKSPACE`:
```bazel
load("@rules_ruby//ruby:deps.bzl", "rb_download")

rb_register_toolchains(
    version = "2.7.5"
)
```


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="rb_register_toolchains-name"></a>name |  base name of resulting repositories, by default "rules_ruby"   |  <code>"rules_ruby"</code> |
| <a id="rb_register_toolchains-version"></a>version |  a semver version of Matz Ruby Interpreter, or a string like [interpreter type]-[version]   |  <code>None</code> |
| <a id="rb_register_toolchains-register"></a>register |  whether to register the resulting toolchains, should be False under bzlmod   |  <code>True</code> |
| <a id="rb_register_toolchains-kwargs"></a>kwargs |  additional parameters to the downloader for this interpreter type   |  none |


