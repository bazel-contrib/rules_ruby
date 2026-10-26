"Implementation details for rb_bundle_install"

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//ruby/private:bundle_fetch.bzl", "BINSTUBS_LOCATION")
load("//ruby/private:providers.bzl", "BundlerInfo", "GemInfo", "RubyFilesInfo")
load(
    "//ruby/private:utils.bzl",
    _convert_env_to_script = "convert_env_to_script",
    _is_windows = "is_windows",
    _normalize_path = "normalize_path",
    _to_rlocation_path = "to_rlocation_path",
)

# Keeps staged copies from colliding with the source files rb_bundle_fetch
# copied into the same package.
_STAGE_DIR = "staged"

def _jars_home(ctx, jars, jars_path):
    # Runtime environment includes JARS_HOME for JRuby to find pre-downloaded JARs,
    # but it needs to be an rlocation path that can be resolved at runtime.
    # On Windows, runfiles manifest doesn't include directories, so we keep a
    # path to a JAR file, then strip a suffix at runtime to get the directory.
    jars_rlocation_path = ""
    if jars_path and jars:
        # Compute rlocation path from the first jar file's short_path.
        # Short path is like "../repo_name/vendor/jars/org/yaml/snakeyaml/1.33/snakeyaml-1.33.jar"
        # We need to extract the base path "repo_name/vendor/jars".
        jar_short_path = _to_rlocation_path(ctx, jars[0])

        # Remove the Maven path portion to get the jars base directory.
        # The jars_path attribute tells us where the jars root is.
        jars_base_idx = jar_short_path.find(jars_path)
        if jars_base_idx >= 0:
            jars_base_end = jars_base_idx + len(jars_path)
            jars_rlocation_path = jar_short_path
            jars_suffix = jar_short_path[jars_base_end:]
            return struct(
                env = {"JARS_HOME": jars_rlocation_path},
                strip = jars_suffix,
            )

    return struct(env = {}, strip = "")

def _staged_path(ctx, file):
    own_prefix = "../{}/".format(ctx.label.workspace_name)
    if file.short_path.startswith(own_prefix):
        return paths.join(_STAGE_DIR, file.short_path[len(own_prefix):])
    if file.short_path.startswith("../"):
        fail("{}: {} is in another repository; only main repository files can be staged".format(
            ctx.label,
            file.owner,
        ))
    return paths.join(_STAGE_DIR, file.short_path)

def _stage(ctx, file, staged):
    """Copies a Gemfile input into one tree at its workspace-relative path.

    Inputs come either from this repository (copied by rb_bundle_fetch) or from
    the main repository (generated files), and Bundler needs the gemspec and the
    files it requires side by side. A copy rather than a symlink is required:
    `__dir__` and `File.realpath` resolve symlinks and would escape the tree.
    """
    path = _staged_path(ctx, file)
    if path not in staged:
        output = ctx.actions.declare_file(path)
        ctx.actions.expand_template(template = file, output = output, substitutions = {})
        staged[path] = output
    return staged[path]

def _normalize_lock(ctx, toolchain, gemfile, srcs):
    """Stages Gemfile.lock with path gem versions taken from the staged gemspecs.

    When the gemspec's version is generated, the checked-in lock can keep the
    real version: unstamped builds then still produce a byte-identical staged
    lock, so the install action and every test stay cached across version bumps.
    """

    # Bundler only looks for the lock next to the Gemfile.
    output = ctx.actions.declare_file(_staged_path(ctx, ctx.file.gemfile) + ".lock")
    env = dict(toolchain.env)
    tools = list(toolchain.files)
    if toolchain.version.startswith("jruby"):
        java_runtime = ctx.toolchains["@bazel_tools//tools/jdk:runtime_toolchain_type"].java_runtime
        env["JAVA_HOME"] = java_runtime.java_home
        tools.extend(java_runtime.files.to_list())
        if _is_windows(ctx):
            env["PATH"] = _normalize_path(ctx, toolchain.ruby.dirname)

    args = ctx.actions.args()
    args.add(ctx.file._normalize_lock)
    args.add(ctx.file.gemfile_lock)
    args.add(gemfile)
    args.add(output)
    ctx.actions.run(
        executable = toolchain.ruby,
        arguments = [args],
        inputs = [ctx.file._normalize_lock, ctx.file.gemfile_lock, gemfile] + srcs,
        outputs = [output],
        env = env,
        tools = tools,
        mnemonic = "BundleLockNormalize",
        progress_message = "Normalizing path gem versions in Gemfile.lock (%{label})",
    )
    return output

def _rb_bundle_install_impl(ctx):
    toolchain = ctx.exec_groups["ruby"].toolchains["@rules_ruby//ruby:toolchain_type"]
    if ctx.attr.ruby != None:
        toolchain = ctx.attr.ruby[platform_common.ToolchainInfo]

    tools = []
    tools.extend(toolchain.files)
    bundler_exe = toolchain.bundle.path

    for gem in ctx.attr.gems:
        if gem[GemInfo].name == "bundler":
            # Use Bundler version defined in Gemfile.lock.
            full_name = "%s-%s" % (gem[GemInfo].name, gem[GemInfo].version)
            bundler_exe = gem.files.to_list()[-1].path + "/gems/" + full_name + "/exe/bundle"
            tools.extend(gem.files.to_list())

    binstubs = ctx.actions.declare_directory(BINSTUBS_LOCATION)
    bundle_path = ctx.actions.declare_directory("vendor/bundle")

    # Bundler resolves BUNDLE_BIN, BUNDLE_PATH and BUNDLE_CACHE_PATH relative
    # to the Gemfile, so walk back up to the execroot first.
    cache_env = {}
    own_prefix = "../{}/".format(ctx.label.workspace_name)
    inputs = [ctx.file.gemfile, ctx.file.gemfile_lock] + ctx.files.srcs
    if any([not (f.is_source and f.short_path.startswith(own_prefix)) for f in inputs]):
        staged = {}
        gemfile = _stage(ctx, ctx.file.gemfile, staged)
        srcs = [_stage(ctx, src, staged) for src in ctx.files.srcs]
        gemfile_lock = _normalize_lock(ctx, toolchain, gemfile, srcs)
        relative_dir = "../" * len(gemfile.dirname.split("/"))
        cache_path = [gem.dirname for gem in ctx.files.gems if gem.basename.endswith(".gem")][0]

        # Kept with forward slashes: Bundler globs this path, and Ruby globs treat backslashes as escapes.
        cache_env["BUNDLE_CACHE_PATH"] = relative_dir + cache_path
    else:
        gemfile = ctx.file.gemfile
        gemfile_lock = ctx.file.gemfile_lock
        srcs = ctx.files.srcs
        relative_dir = "../../" + "../" * len(gemfile.short_path.split("/")[2:-1])

    jar_files = ctx.files.jars if ctx.attr.jars else []

    attr_env = {
        key: ctx.expand_location(value, ctx.attr.data)
        for key, value in ctx.attr.env.items()
    }

    env = {}
    env.update(toolchain.env)
    env.update(attr_env)

    bundler_env = {}
    bundler_env.update(attr_env)
    jars_home_strip_suffix = ""

    if toolchain.version.startswith("jruby"):
        java_toolchain = ctx.exec_groups["ruby"].toolchains["@bazel_tools//tools/jdk:runtime_toolchain_type"]
        tools.extend(java_toolchain.java_runtime.files.to_list())
        env.update({
            "JARS_SKIP": "true",  # Avoid installing extra dependencies during install.
            "JAVA_HOME": java_toolchain.java_runtime.java_home,
        })
        jars_info = _jars_home(ctx, jar_files, ctx.attr.jars_path)
        jars_home_strip_suffix = jars_info.strip
        env.update(jars_info.env)
        bundler_env.update(jars_info.env)

    if _is_windows(ctx):
        script = ctx.actions.declare_file("bundle_install_{}.cmd".format(ctx.label.name))
        template = ctx.file._bundle_install_cmd_tpl
        path = attr_env.get("PATH", "%PATH%")
        env.update({"PATH": _normalize_path(ctx, toolchain.ruby.dirname) + ";" + path})
    else:
        script = ctx.actions.declare_file("bundle_install_{}.sh".format(ctx.label.name))
        template = ctx.file._bundle_install_sh_tpl
        path = attr_env.get("PATH", "$PATH")
        env.update({"PATH": toolchain.ruby.dirname + ":" + path})

    # See https://bundler.io/v2.5/man/bundle-config.1.html for confiugration keys.
    env.update(cache_env)
    env.update({
        "BUNDLE_BIN": "".join([relative_dir, binstubs.path]),
        "BUNDLE_DEPLOYMENT": "1",
        "BUNDLE_DISABLE_SHARED_GEMS": "1",
        "BUNDLE_DISABLE_VERSION_CHECK": "1",
        "BUNDLE_GEMFILE": _normalize_path(ctx, gemfile.path),
        "BUNDLE_IGNORE_CONFIG": "1",
        "BUNDLE_PATH": _normalize_path(ctx, "".join([relative_dir, bundle_path.path])),
        "BUNDLE_SHEBANG": _normalize_path(ctx, toolchain.ruby.short_path),
    })

    # Binstubs generation runs with the HOST ruby, which validates gems against
    # the running platform. For a cross-platform bundle (e.g. installed with
    # --target-rbconfig for another OS/arch) the host can't see those gems'
    # native extensions and `binstubs --all` fails. `binstubs = False` skips it,
    # just materializing the (empty) declared binstubs dir instead.
    if ctx.attr.binstubs:
        binstubs_cmd = "{} {} binstubs --all".format(
            _normalize_path(ctx, toolchain.ruby.path),
            _normalize_path(ctx, bundler_exe),
        )
    elif _is_windows(ctx):
        binstubs_cmd = 'if not exist "{p}" mkdir "{p}"'.format(p = _normalize_path(ctx, binstubs.path))
    else:
        binstubs_cmd = 'mkdir -p "{}"'.format(binstubs.path)

    ctx.actions.expand_template(
        template = template,
        output = script,
        substitutions = {
            "{env}": _convert_env_to_script(ctx, env),
            "{bundler_exe}": _normalize_path(ctx, bundler_exe),
            "{ruby_path}": _normalize_path(ctx, toolchain.ruby.path),
            "{binstubs_cmd}": binstubs_cmd,
            "{extra_args}": " ".join([
                ctx.expand_location(arg, ctx.attr.data)
                for arg in ctx.attr.extra_args
            ]),
        },
    )

    ctx.actions.run(
        exec_group = "ruby",
        executable = script,
        inputs = depset([gemfile, gemfile_lock] + srcs + ctx.files.data + ctx.files.gems + jar_files),
        outputs = [binstubs, bundle_path],
        mnemonic = "BundleInstall",
        progress_message = "Running bundle install (%{label})",
        tools = tools,
        use_default_shell_env = True,
    )

    files = [
        gemfile,
        gemfile_lock,
        binstubs,
        bundle_path,
    ] + srcs + jar_files

    return [
        DefaultInfo(
            files = depset(files),
            runfiles = ctx.runfiles(files),
        ),
        # `gems` exposes JUST the installed vendor/bundle tree (no Gemfile/
        # binstubs), so consumers can package it cleanly — e.g.
        # `filegroup(output_group = "gems")` + pkg_files strip_prefix to lay the
        # gems into a container's BUNDLE_PATH without the surrounding files.
        OutputGroupInfo(gems = depset([bundle_path])),
        RubyFilesInfo(
            binary = None,
            transitive_srcs = depset([gemfile, gemfile_lock] + srcs),
            transitive_deps = depset(),
            transitive_data = depset(),
        ),
        BundlerInfo(
            bin = binstubs,
            env = bundler_env,
            gemfile = gemfile,
            jars_home_strip_suffix = jars_home_strip_suffix,
            path = bundle_path,
        ),
    ]

rb_bundle_install = rule(
    _rb_bundle_install_impl,
    attrs = {
        "gemfile": attr.label(
            allow_single_file = ["Gemfile"],
            mandatory = True,
            doc = "Gemfile to install dependencies from. If it, `gemfile_lock` or any of " +
                  "`srcs` comes from outside this target's repository, such as a generated " +
                  "file, all of them are copied into one tree at their workspace-relative " +
                  "paths before installation, with `gemfile_lock` placed next to the Gemfile.",
        ),
        "gemfile_lock": attr.label(
            allow_single_file = ["Gemfile.lock"],
            mandatory = True,
            doc = "Gemfile.lock to install dependencies from. When inputs are staged " +
                  "(see `gemfile`), the versions of path gems in the staged copy are " +
                  "rewritten to match their gemspecs.",
        ),
        "gems": attr.label_list(
            allow_files = [".gem"],
            mandatory = True,
            doc = "List of gems in vendor/cache that are used to install dependencies from.",
        ),
        "jars": attr.label_list(
            allow_files = [".jar"],
            doc = "JAR dependencies for JRuby gems.",
        ),
        "jars_path": attr.string(
            doc = "Path to the directory containing JAR dependencies (set as JARS_HOME).",
        ),
        "srcs": attr.label_list(
            allow_files = True,
            doc = "Files the Gemfile needs besides Gemfile.lock, typically the gemspec " +
                  "and the version file it requires. They may be generated files " +
                  "(see `gemfile`).",
        ),
        "env": attr.string_dict(
            doc = "Environment variables to use during installation. Values support " +
                  "`$(location ...)`/`$(execpath ...)` make-variable expansion against " +
                  "`data` (e.g. prepend a generated cross-compiler wrapper dir onto PATH).",
        ),
        "binstubs": attr.bool(
            default = True,
            doc = "Whether to run `bundle binstubs --all` after install. Set False for " +
                  "cross-platform bundles (installed with a foreign --target-rbconfig): the " +
                  "host ruby can't validate the target's native extensions, so binstubs " +
                  "generation fails. When False the (empty) binstubs dir is still created.",
        ),
        "extra_args": attr.string_list(
            doc = "Extra arguments appended to the `bundle install` command line. " +
                  "Supports `$(location ...)`/`$(rootpath ...)`/`$(execpath ...)` make-variable " +
                  "expansion against `data`. For example " +
                  "`[\"--target-rbconfig\", \"$(location //path:rbconfig.rb)\"]` " +
                  "to install a different platform's precompiled gems (cross-platform bundle).",
        ),
        "data": attr.label_list(
            allow_files = True,
            doc = "Files referenced from `extra_args` via `$(location ...)` expansion. " +
                  "They are also added as inputs to the `bundle install` action.",
        ),
        "ruby": attr.label(
            doc = "Override Ruby toolchain to use when installing the gem.",
            providers = [platform_common.ToolchainInfo],
        ),
        "_bundle_install_sh_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//ruby/private/bundle_install:bundle_install.sh.tpl",
        ),
        "_normalize_lock": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//ruby/private/bundle_install:normalize_lock.rb",
        ),
        "_bundle_install_cmd_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//ruby/private/bundle_install:bundle_install.cmd.tpl",
        ),
        "_windows_constraint": attr.label(
            default = "@platforms//os:windows",
        ),
    },
    # JRuby runs Ruby and Java tools in the same action, on the same platform.
    exec_groups = {
        "ruby": exec_group(toolchains = [
            "@rules_ruby//ruby:toolchain_type",
            "@bazel_tools//tools/jdk:runtime_toolchain_type",
        ]),
    },
    doc = """
Installs Bundler dependencies from cached gems.

You normally don't need to call this rule directly as it's an internal one
used by `rb_bundle_fetch()`.
    """,
)
