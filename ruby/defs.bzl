"Public API for rules"

load("//ruby/private:binary.bzl", _rb_binary = "rb_binary")
load("//ruby/private:bundle_install.bzl", _rb_bundle_install = "rb_bundle_install")
load("//ruby/private:gem.bzl", _rb_gem = "rb_gem")
load("//ruby/private:gem_build.bzl", _rb_gem_build = "rb_gem_build")
load("//ruby/private:gem_install.bzl", _rb_gem_install = "rb_gem_install")
load("//ruby/private:gem_push.bzl", _rb_gem_push = "rb_gem_push")
load("//ruby/private:library.bzl", _rb_library = "rb_library")
load("//ruby/private:test.bzl", _rb_test = "rb_test")

rb_binary = _rb_binary
rb_bundle_install = _rb_bundle_install
rb_gem = _rb_gem
rb_gem_build = _rb_gem_build
rb_gem_install = _rb_gem_install
rb_gem_push = _rb_gem_push
rb_library = _rb_library
rb_test = _rb_test
