# Rails Example

This example demonstrates how to use Bazel and rules_ruby to build and test a
Ruby on Rails application. The actual Rails application lives under the
`people_tracker` directory.

## Development Workflow

### Bazel Testing

```bash
bazel test //...
```

### Direnv Setup

This project uses [direnv](https://direnv.net/) to provide access to `rails`
and other related binaries on the command-line. Make sure you have direnv
installed and allow the `.envrc` file:

```bash
direnv allow
```

#### Rails Command

Once direnv is configured, change into the `people_tracker/` directory and run
`rails` commands directly for development tasks instead of using
`people_tracker/bin/rails`:

```bash
cd people_tracker/
rails test
rails generate scaffold Foo
rails server
```

The `rails` command will automatically use the Ruby gems installed by Bazel,
so there is no need to run `bundle install` separately.

## Implementation Notes

### Rails Test Setup

To run Rails tests with Bazel, you need to create test macros that configure the
Rails test environment. Create a file at `people_tracker/test/rails_test.bzl`:

```starlark
"""Module for app-specific rails helpers and macros."""

load("@rules_ruby//rails:rails_test_factory.bzl", "rails_test_factory")

# This is the directory in the Bazel workspace where the test helpers reside.
# This is used to generate the test helper labels and appropriate includes.
_TEST_PKG = "people_tracker/test"

# The rails_test macro is used to define Bazel test targets for Rails model and
# controller tests. See examples in people_tracker/test/models/BUILD.bazel.
rails_test = rails_test_factory.new_test(test_package = _TEST_PKG)

# The rails_system_test macro is used to define Bazel test targets for Rails
# system tests.  See examples in people_tracker/test/system/BUILD.bazel.
rails_system_test = rails_test_factory.new_system_test(test_package = _TEST_PKG)
```

These macros (`rails_test` and `rails_system_test`) can then be used in your
`BUILD.bazel` files to define test targets for your Rails application.

The tests are configured to use a SQLite in-memory database for fast, isolated
test execution.

### Patches

To prevent Ruby from escaping the sandbox, Ruby requires patches to `Kernel`
functions. This example implements the patches to
`people_tracker/config/initializers/bazel_ruby_patches.rb`. Being included in
the `config/initializers` directory for a Rails app ensures that it is applied
early in the Rails load process. However, we need to apply it earlier in the
load process for tests. So, we add it to the top of the
`people_tracker/test/test_helper.rb`.

### Direnv - Using rails from the command-line

If you install [direnv](https://direnv.net/) and allow it to load the
environment defined in the `.envrc` files, you can run `rails` commands using
the Ruby and Rails installed by Bazel. The `rails` command will automatically
use the Ruby gems installed by Bazel, so there is no need to run `bundle
install` separately.
