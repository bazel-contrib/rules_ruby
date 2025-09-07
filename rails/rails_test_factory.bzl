"""Public definition for `rails_test_factory`."""

load(
    "//rails/private:rails_test_factory.bzl",
    _rails_test_factory = "rails_test_factory",
)

rails_test_factory = _rails_test_factory
