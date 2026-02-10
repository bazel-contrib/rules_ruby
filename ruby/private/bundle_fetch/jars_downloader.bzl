"Fetches JAR dependencies for Java-platform Ruby gems from Maven Central."

_MAVEN_CENTRAL_URL = "https://repo1.maven.org/maven2"
_RUBYGEMS_API_URL = "https://rubygems.org/api/v2/rubygems/{gem}/versions/{version}.json"

def fetch_jars_for_gem(repository_ctx, gem, jars_path):
    """Fetches all JAR dependencies for a Java gem.

    Args:
        repository_ctx: Repository context.
        gem: Gem struct with name and version fields.
        jars_path: Base path for storing JARs.

    Returns:
        List of downloaded JAR paths.
    """
    if not _is_java_gem(gem):
        return []

    requirements = _fetch_gem_requirements(repository_ctx, gem)
    jar_paths = []

    for req in requirements:
        jar = _parse_jar_requirement(req)
        if jar:
            jar_path = _download_jar(repository_ctx, jar, jars_path)
            jar_paths.append(jar_path)

    return jar_paths

def _is_java_gem(gem):
    """Checks if a gem is a Java-platform gem.

    Java gems have "-java" suffix in their version string (e.g., "5.0.1-java").

    Args:
        gem: Gem struct with name and version fields.

    Returns:
        True if the gem is a Java-platform gem.
    """
    return gem.version.endswith("-java") or "-java-" in gem.version

def _fetch_gem_requirements(repository_ctx, gem):
    """Fetches JAR requirements for a gem from RubyGems API.

    Queries the RubyGems API to get the gem's metadata and extracts
    the JAR requirements from the "requirements" field.

    Args:
        repository_ctx: Repository context.
        gem: Gem struct with name and version fields.

    Returns:
        List of JAR requirement strings (e.g., ["jar org.yaml:snakeyaml, 1.33"]).
    """

    # Extract base version without platform suffix
    # e.g., "psych-5.0.1-java" -> name="psych", version="5.0.1"
    base_version = gem.version.replace("-java", "")

    url = _RUBYGEMS_API_URL.format(
        gem = gem.name,
        version = base_version,
    )

    # Download gem version info from RubyGems API
    file_name = "_gem_info_{}-{}.json".format(gem.name, gem.version)
    result = repository_ctx.download(
        url = url,
        output = file_name,
    )

    if not result.success:
        # buildifier: disable=print
        print("Warning: Failed to fetch gem info for {}".format(gem.name))
        return []

    gem_info = json.decode(repository_ctx.read(file_name))
    repository_ctx.delete(file_name)

    return gem_info.get("requirements", [])

def _parse_jar_requirement(requirement):
    """Parses a JAR requirement string into Maven coordinates.

    JAR requirements follow the format: "jar group:artifact, version"
    Example: "jar org.yaml:snakeyaml, 1.33"

    Args:
        requirement: JAR requirement string.

    Returns:
        struct with group_id, artifact_id, version fields, or None if not a JAR requirement.
    """
    if not requirement.startswith("jar "):
        return None

    # Remove "jar " prefix
    coords = requirement[4:].strip()

    # Split by comma to separate group:artifact from version
    parts = coords.split(",")
    if len(parts) != 2:
        return None

    group_artifact = parts[0].strip()
    version = parts[1].strip()

    # Split group:artifact
    ga_parts = group_artifact.split(":")
    if len(ga_parts) != 2:
        return None

    return struct(
        group_id = ga_parts[0],
        artifact_id = ga_parts[1],
        version = version,
    )

def _jar_to_maven_path(jar):
    """Converts JAR coordinates to Maven repository path.

    Args:
        jar: struct with group_id, artifact_id, version fields.

    Returns:
        Maven-style path for the JAR (e.g., "org/yaml/snakeyaml/1.33/snakeyaml-1.33.jar").
    """
    group_path = jar.group_id.replace(".", "/")
    filename = "{artifact}-{version}.jar".format(
        artifact = jar.artifact_id,
        version = jar.version,
    )
    return "{group}/{artifact}/{version}/{filename}".format(
        group = group_path,
        artifact = jar.artifact_id,
        version = jar.version,
        filename = filename,
    )

def _download_jar(repository_ctx, jar, jars_path):
    """Downloads a JAR from Maven Central.

    Args:
        repository_ctx: Repository context.
        jar: struct with group_id, artifact_id, version fields.
        jars_path: Base path for storing JARs.

    Returns:
        Path to the downloaded JAR relative to jars_path.
    """
    maven_path = _jar_to_maven_path(jar)
    url = "{maven}/{path}".format(
        maven = _MAVEN_CENTRAL_URL,
        path = maven_path,
    )

    output_path = "{jars}/{path}".format(
        jars = jars_path,
        path = maven_path,
    )

    result = repository_ctx.download(
        url = url,
        output = output_path,
    )

    if not result.success:
        fail("Failed to download JAR from {}: {}".format(url, result))

    return maven_path
