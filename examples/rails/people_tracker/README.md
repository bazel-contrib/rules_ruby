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

### Testing

```bash
bazel test //...
```
