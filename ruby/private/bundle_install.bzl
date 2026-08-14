"Implementation details for rb_bundle_install"

load("//ruby/private:bundle_fetch.bzl", "BINSTUBS_LOCATION")
load("//ruby/private:providers.bzl", "BundlerInfo", "GemInfo", "RubyFilesInfo")
load(
    "//ruby/private:utils.bzl",
    _convert_env_to_script = "convert_env_to_script",
    _is_windows = "is_windows",
    _normalize_path = "normalize_path",
    _to_rlocation_path = "to_rlocation_path",
)

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

def _rb_bundle_install_impl(ctx):
    toolchain = ctx.toolchains["@rules_ruby//ruby:toolchain_type"]
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
        java_toolchain = ctx.toolchains["@bazel_tools//tools/jdk:runtime_toolchain_type"]
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

    # Calculate relative location between BUNDLE_GEMFILE and BUNDLE_PATH.
    relative_dir = "../../"
    for _ in ctx.file.gemfile.short_path.split("/")[2:-1]:
        relative_dir += "../"

    # See https://bundler.io/v2.5/man/bundle-config.1.html for confiugration keys.
    env.update({
        "BUNDLE_BIN": "".join([relative_dir, binstubs.path]),
        "BUNDLE_DEPLOYMENT": "1",
        "BUNDLE_DISABLE_SHARED_GEMS": "1",
        "BUNDLE_DISABLE_VERSION_CHECK": "1",
        "BUNDLE_GEMFILE": _normalize_path(ctx, ctx.file.gemfile.path),
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
        executable = script,
        inputs = depset([ctx.file.gemfile, ctx.file.gemfile_lock] + ctx.files.srcs + ctx.files.data + ctx.files.gems + jar_files),
        outputs = [binstubs, bundle_path],
        mnemonic = "BundleInstall",
        progress_message = "Running bundle install (%{label})",
        tools = tools,
        use_default_shell_env = True,
    )

    files = [
        ctx.file.gemfile,
        ctx.file.gemfile_lock,
        binstubs,
        bundle_path,
    ] + ctx.files.srcs + jar_files

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
            transitive_srcs = depset([ctx.file.gemfile, ctx.file.gemfile_lock] + ctx.files.srcs),
            transitive_deps = depset(),
            transitive_data = depset(),
            bundle_env = {},
        ),
        BundlerInfo(
            bin = binstubs,
            env = bundler_env,
            gemfile = ctx.file.gemfile,
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
            doc = "Gemfile to install dependencies from.",
        ),
        "gemfile_lock": attr.label(
            allow_single_file = ["Gemfile.lock"],
            mandatory = True,
            doc = "Gemfile.lock to install dependencies from.",
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
            doc = "List of Ruby source files used to build the library.",
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
        "_bundle_install_cmd_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//ruby/private/bundle_install:bundle_install.cmd.tpl",
        ),
        "_windows_constraint": attr.label(
            default = "@platforms//os:windows",
        ),
    },
    toolchains = [
        "@rules_ruby//ruby:toolchain_type",
        "@bazel_tools//tools/jdk:runtime_toolchain_type",
    ],
    doc = """
Installs Bundler dependencies from cached gems.

You normally don't need to call this rule directly as it's an internal one
used by `rb_bundle_fetch()`.
    """,
)
