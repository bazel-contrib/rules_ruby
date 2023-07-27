RubyFilesInfo = provider(
    "Provider for Ruby files",
    fields = ["transitive_data", "transitive_deps", "transitive_srcs"],
)

# https://bazel.build/rules/depsets

def get_transitive_srcs(srcs, deps):
    """Obtain the source files for a target and its transitive dependencies.

    Args:
      srcs: a list of source files
      deps: a list of targets that are direct dependencies
    Returns:
      a collection of the transitive sources
    """
    return depset(
        srcs,
        transitive = [dep[RubyFilesInfo].transitive_srcs for dep in deps],
    )

def get_transitive_data(srcs, deps):
    """Obtain the data files for a target and its transitive dependencies.

    Args:
      srcs: a list of source files
      deps: a list of targets that are direct dependencies
    Returns:
      a collection of the transitive data files
    """
    return depset(
        srcs,
        transitive = [dep[RubyFilesInfo].transitive_data for dep in deps],
    )

def get_transitive_deps(deps):
    """Obtain the dependencies for a target and its transitive dependencies.

    Args:
      deps: a list of targets that are direct dependencies
    Returns:
      a collection of the transitive dependencies
    """
    return depset(
        deps,
        transitive = [dep[RubyFilesInfo].transitive_deps for dep in deps],
    )
