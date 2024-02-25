"""
Parses a Gemfile.lock purely in Starlark.

Largely based on https://github.com/sushain97/rules_ruby/blob/master/tools/ruby/gemfile_parser.bzl (private).
Modifications include:
  - Support for parsing out the gem remote URL.
  - Usage of structs with extra fields as return values.
"""

def _parse_package(line, remote):
    """Parses an exact package specification from a single line of a Gemfile.lock.

    The Gemfile.lock format uses two spaces for each level of indentation. The
    lines that we're interested in are nested underneath the `GEM.specs`
    section (the concrete gems required and their exact versions).

    The lines that are parsed out of the 'GEM.specs' section will have four
    leading spaces, and consist of the package name and exact version needed
    in parenthesis.

    >    gem-name (gem-version)

    What's returned is a struct that has the following fields in this case:

    > struct(
    >   name = "gem-name",
    >   version = "gem-version",
    >   full_name = "gem-name-gem-version",
    >   filename = "gem-name-gem-version.gem",
    >   remote = "https://rubygems.org"
    > )

    If the line does not match that format, `None` is returned.
    """

    prefix = line[0:4]
    if not prefix.isspace():
        return None

    suffix = line[4:]
    if suffix[0].isspace():
        return None

    version_start = suffix.find(" (")
    if version_start < 0:
        return None

    package = suffix[0:version_start]
    version = suffix[version_start + 2:-1]

    return struct(
        name = package,
        version = version,
        filename = "%s-%s.gem" % (package, version),
        full_name = "%s-%s" % (package, version),
        remote = remote,
    )

def _parse_top_section(line):
    """Parse a top-level section name.

    Returns a top-level section name ("PATH", "GEM", "PLATFORMS",
    "DEPENDENCIES", etc.), or `None` if the line is empty or contains leading
    space.
    """

    if line == "" or line[0].isspace():
        return None

    return line

def _parse_remote(line):
    """Parse a remote URL for packages.

    An example line is:
    >   remote: https://rubygems.org/
    """
    prefix = "  remote: "
    if line.startswith(prefix):
        return line.removeprefix(prefix).strip()

    return None

def _parse_git_package(lines):
    """Parse a Git specification from several lines of a Gemfile.lock.

    The relevant lines begin with either `remote` or `revision`.

    > remote: path:to/remote.git
    > revision: rev

    What's returned is a dict that will have two fields:

    > { "revision": "rev", "remote": "path:to/remote.git" }

    in this case.

    If the line does not match that format, an error is raised.
    """
    remote = None
    revision = None

    for line in lines:
        if "remote: " in line:
            remote = line.split(":", 1)[1].strip()
        elif "revision: " in line:
            revision = line.split(":", 1)[1].strip()

    if revision == None or remote == None:
        fail("Unable to parse git package from gemfile: {}. Found remote={}, revision={}.".format(lines, remote, revision))

    return {"revision": revision, "remote": remote}

def parse_gemfile_lock(content, bundler_remote):
    """Parses a Gemfile.lock.

    Find lines in the content of a Gemfile.lock that look like package
    constraints.

    Args:
        content: Gemfile.lock contents
        bundler_remote: Remote URL for the bundler package.

    Returns:
        struct with parsed Gemfile.lock
    """

    remote_packages = []
    git_packages = []
    bundler = None
    remote = None

    inside_gem = False
    inside_git = False
    inside_bundled_with = False

    git_lines = []

    for line in content.splitlines():
        top_section = _parse_top_section(line)
        if top_section != None:
            # Toggle gem specification parsing.
            if top_section == "GEM":
                inside_gem = True
                remote = None

            # Toggle bundler version parsing. Skip to the next line which
            # has the actual version.
            inside_bundled_with = (top_section == "BUNDLED WITH")
            if inside_bundled_with:
                continue

            # Toggle git specification parsing.
            inside_git = (top_section == "GIT")

        # Only parse gem specifications from the GEM section.
        if inside_gem:
            if remote:
                info = _parse_package(line, remote)
                if info != None:
                    remote_packages.append(info)
            else:
                remote = _parse_remote(line)

        # Only parse git specifications from the GIT section.
        if inside_git:
            if line == "":
                # The git section is complete, parse its information.
                git_packages.append(_parse_git_package(git_lines))
                git_lines = []
                inside_git = False
            else:
                # Buffer up the git section.
                git_lines.append(line)

        # Only parse bundler version from the BUNDLED_WITH section.
        if inside_bundled_with:
            version = line.strip()
            bundler = struct(
                name = "bundler",
                version = version,
                filename = "bundler-%s.gem" % version,
                full_name = "bundler-%s" % version,
                remote = bundler_remote,
            )
            inside_bundled_with = False

    return struct(
        bundler = bundler,
        git_packages = git_packages,
        remote_packages = remote_packages,
    )
