# People Tracker

## Development Workflow

### Environment Setup

This project uses [direnv](https://direnv.net/) to provide access to `rails`
and other related binaries on the command-line. Make sure you have direnv
installed and allow the `.envrc` file:

```bash
direnv allow
```

### Rails Command

Once direnv is configured, change into the `people_tracker/` directory and run
`rails` commands directly instead of using `people_tracker/bin/rails`:

```bash
cd people_tracker/
rails test
rails generate scaffold Foo
rails server
```

### Bazel Testing

```bash
bazel test //...
```

## Implementation Notes

### Patches

To prevent Ruby from escaping the sandbox, one needs to patch `Kernel`
functions. This example implements the patches to
`people_tracker/config/initializers/bazel_ruby_patches.rb`. Being included in
the `config/initializers` directory for a Rails app ensures that it is applied
early in the Rails load process. However, we need to apply it earlier in the
load process for tests. So, we add it to the top of the
`examples/rails/people_tracker/test/test_helper.rb`.

### Direnv - Using rails from the command-line

If you install [direnv](https://direnv.net/) and allow it to load the
environment defined in the `.envrc` files, you can run `rails` commands using
the Ruby and Rails installed by Bazel.
