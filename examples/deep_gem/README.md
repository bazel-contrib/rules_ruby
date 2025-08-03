# Deep Gem Example

This example demonstrates how to define a Ruby gem that does not reside at the root of the
Bazel workspace and how to reference files using standard Bazel package notation in the
`MODULE.bazel` file.

## Overview

Unlike typical Ruby gems that live at the workspace root, this example shows how to
structure a gem in a subdirectory (`hello_world/`) while still being able to reference its
files using Bazel's standard package notation.

## Key Features

- **Non-root gem location**: The gem is located in `hello_world/` subdirectory, not at the
  workspace root
- **Standard Bazel package notation**: Files are referenced using standard Bazel labels like
  `//hello_world/lib/hello_world:version.rb`
- **Proper dependency management**: Demonstrates how to configure `bundle_fetch` with deep
  gem structure

## Project Structure

```
examples/deep_gem/
├── MODULE.bazel           # Workspace configuration with deep gem references
├── hello_world/           # Gem directory (not at root)
│   ├── hello_world.gemspec
│   ├── Gemfile
│   ├── Gemfile.lock
│   ├── lib/
│   │   ├── hello_world.rb
│   │   └── hello_world/
│   │       ├── speaker.rb
│   │       └── version.rb  # Referenced as //hello_world/lib/hello_world:version.rb
│   └── spec/
│       ├── BUILD.bazel
│       ├── hello_world_spec.rb
│       ├── speaker_spec.rb
│       └── spec_helper.rb
```

## Bazel Package Notation

The key insight of this example is how to reference gem files using standard Bazel package
notation in `MODULE.bazel`:

```starlark
ruby.bundle_fetch(
    name = "bundle",
    srcs = [
        "//hello_world:hello_world.gemspec",           # Gemspec in subdirectory
        "//hello_world/lib/hello_world:version.rb",    # Version file in nested structure
    ],
    gemfile = "//hello_world:Gemfile",
    gemfile_lock = "//hello_world:Gemfile.lock",
)
```

### Package Reference Examples

- `//hello_world:hello_world.gemspec` - References the gemspec file in the hello_world directory
- `//hello_world/lib/hello_world:version.rb` - References the version.rb file in the nested
  lib/hello_world directory
- `//hello_world:Gemfile` - References the Gemfile in the hello_world directory

## Running Tests

The example includes comprehensive RSpec tests organized with proper separation of concerns:

```bash
# Run all tests
bazel test //...

# Run specific test suites
bazel test //hello_world/spec:hello_world_spec
bazel test //hello_world/spec:speaker_spec

# Run all spec tests
bazel test //hello_world/spec:all
```

## Benefits

This approach provides several advantages:

1. **Workspace Organization**: Allows gems to be organized in subdirectories for better
   project structure
2. **Standard Bazel Conventions**: Uses familiar Bazel package notation for file references
3. **Scalability**: Enables multiple gems within a single workspace without conflicts
4. **Maintainability**: Clear separation of concerns with proper directory structure

## Usage

This example serves as a template for projects that need to:

- Define gems in subdirectories rather than at the workspace root
- Reference gem files using standard Bazel package notation
- Maintain proper dependency management with complex directory structures
- Organize multiple gems within a single Bazel workspace
