"""Module for app-specific rails helpers and macros."""

load("@rules_ruby//rails:rails_test_factory.bzl", "rails_test_factory")

_TEST_PKG = "people_tracker/test"

rails_test = rails_test_factory.new_test(test_package = _TEST_PKG)

rails_system_test = rails_test_factory.new_system_test(test_package = _TEST_PKG)
