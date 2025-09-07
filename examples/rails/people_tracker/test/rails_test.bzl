"""Module for app-specific rails helpers and macros."""

load("//rails:rails_test_factory.bzl", "rails_test_factory")

_TEST_PKG = "lrtc/test"

rails_test = rails_test_factory.new_test(test_package = _TEST_PKG)

rails_system_test = rails_test_factory.new_system_test(test_package = _TEST_PKG)
