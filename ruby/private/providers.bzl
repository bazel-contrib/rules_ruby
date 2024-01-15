"Providers for interoperability between rules"

RubyFilesInfo = provider(
    "Provider for Ruby files",
    fields = ["transitive_data", "transitive_deps", "transitive_srcs", "bundle_env"],
)

BundlerInfo = provider(
    "Provider for Bundler installation",
    fields = ["bin", "gemfile", "path", "env"],
)

GemInfo = provider(
    "Provider for a packed Ruby gem",
    fields = ["name", "version"],
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

def get_transitive_data(data, deps):
    """Obtain the data files for a target and its transitive dependencies.

    Args:
      data: a list of data files
      deps: a list of targets that are direct dependencies
    Returns:
      a collection of the transitive data files
    """
    return depset(
        data,
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

# https://bazel.build/extending/rules#runfiles
def get_transitive_runfiles(runfiles, srcs, data, deps):
    """Obtain the runfiles for a target, its transitive data files and dependencies.

    Args:
      runfiles: the runfiles
      srcs: a list of source files
      data: a list of data files
      deps: a list of targets that are direct dependencies
    Returns:
      the runfiles
    """
    transitive_runfiles = []
    for targets in (srcs, data, deps):
        for target in targets:
            transitive_runfiles.append(target[DefaultInfo].default_runfiles)
    return runfiles.merge_all(transitive_runfiles)

def get_bundle_env(envs, deps):
    """Obtain the BUNDLE_* environment variables for a target and its transitive dependencies.

    Args:
      envs: a list of environment variables
      deps: a list of targets that are direct dependencies
    Returns:
      a collection of the transitive environment variables
    """
    bundle_env = {}

    transitive_deps = get_transitive_deps(deps).to_list()
    for dep in transitive_deps:
        bundle_env.update(dep[RubyFilesInfo].bundle_env)
        if BundlerInfo in dep:
            bundle_env.update(dep[BundlerInfo].env)

    for env in envs:
        if env.startswith("BUNDLE_"):
            bundle_env[env] = envs[env]
    return bundle_env
