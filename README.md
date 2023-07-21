# Ruby Rules for Bazel

## Overview

This repository hosts [Ruby][1] language ruleset for [Bazel][2].

The ruleset is known to work with Bazel 5 and 6.

## Getting Started

Pending the first release.

## Documentation

- See [repository rules][3] for the documentation of `WORKSPACE` rules.
- See [rules][4] for the documentation of `BUILD` rules.

## Toolchains

The following toolchains are known to work and tested on CI.

| Ruby             | Linux | macOS | Windows |
|------------------|-------|-------|---------|
| MRI 3.2          | 🟩    | 🟩    | 🟩      |
| MRI 3.1          | 🟩    | 🟩    | 🟩      |
| MRI 3.0          | 🟩    | 🟩    | 🟩      |
| JRuby 9.4        | 🟩    | 🟩    | 🟩      |
| JRuby 9.3        | 🟩    | 🟩    | 🟩      |
| TruffleRuby 23.0 | 🟩    | 🟩    | 🟥      |

### MRI

On Linux and macOS, [ruby-build][5] is used to install MRI from sources.
Keep in mind, that it takes some time for compilation to complete.

On Windows, [RubyInstaller][6] is used to install MRI.

### JRuby

On all operating systems, JRuby is downloaded manually.
It uses Bazel runtime Java toolchain as JDK.

*Note: You might need to expose `HOME` variable for JRuby to work.
See [`examples/gem/.bazelrc`][7] to learn how to do that.
This is to be fixed in https://github.com/jruby/jruby/issues/5661.*

*Note: If you get `Errno::EACCES: Permission denied - NUL` error on Windows,
you might need to configure JDK to allow access.
See [`examples/gem/.bazelrc`][7] to learn how to do that.
This is described in https://github.com/jruby/jruby/issues/7182#issuecomment-1112953015.*

### TruffleRuby

On Linux and macOS, [ruby-build][5] is used to install TruffleRuby.
Windows is not supported.

*Note: You might need to expose `HOME` variable for JRuby to work.
See [`examples/gem/.bazelrc`][7] to learn how to do that.
This is to be fixed in https://github.com/oracle/truffleruby/issues/2784.*

### Other

On Linux and macOS, you can potentially use any Ruby distribution that is supported by [ruby-build][5].
However, some are known not to work or work only partially (e.g. mRuby has no bundler support).

[1]: https://www.ruby-lang.org
[2]: https://bazel.build
[3]: docs/repository_rules.md
[4]: docs/rules.md
[5]: https://github.com/rbenv/ruby-build
[6]: https://rubyinstaller.org
[7]: examples/gem/.bazelrc
