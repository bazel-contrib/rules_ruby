load("//ruby/private:binary.bzl", _rb_binary = "rb_binary")
load("//ruby/private:gem_build.bzl", _rb_gem_build = "rb_gem_build")
load("//ruby/private:gem_push.bzl", _rb_gem_push = "rb_gem_push")
load("//ruby/private:library.bzl", _rb_library = "rb_library")
load("//ruby/private:test.bzl", _rb_test = "rb_test")

rb_binary = _rb_binary
rb_gem_build = _rb_gem_build
rb_gem_push = _rb_gem_push
rb_library = _rb_library
rb_test = _rb_test
