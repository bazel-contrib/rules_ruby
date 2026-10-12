# Stamped gem

The gem version lives only in `version.bzl`. `lib/greeter/version.rb` is
generated from it, with the real version under `--stamp` and
`UNSTAMPED_VERSION` otherwise, and `Gemfile.lock` records the real version.

Because a generated file is listed in `bundle_fetch(srcs = ...)`, the bundle
stages its Gemfile inputs at build time and rewrites the path gem's version in
its copy of `Gemfile.lock` to match the gemspec. Bumping `VERSION` (and the
lock) therefore leaves every test cached, while `bazel build --stamp
//:gem-build` packages the real version.

The unstamped version must still satisfy any requirement other gems in the
bundle place on this gem. For example, a gem requiring `greeter (~> 1.2)`
would make Bundler reject `0.0.0`.

```bash
bazel test //...
bazel test --stamp //...
bazel build --stamp //:gem-build
```
