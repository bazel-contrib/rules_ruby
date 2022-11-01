RubyFiles = provider(fields = ["transitive_srcs"])

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
	transitive = [dep[RubyFiles].transitive_srcs for dep in deps])
