"Implementation details for rb_bundle_install"

load("//ruby/private:bundle_fetch.bzl", "BINSTUBS_LOCATION")
load("//ruby/private:providers.bzl", "BundlerInfo", "GemInfo", "RubyFilesInfo")
load(
    "//ruby/private:utils.bzl",
    _convert_env_to_script = "convert_env_to_script",
    _is_windows = "is_windows",
    _normalize_path = "normalize_path",
)

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

    env = {}
    env.update(toolchain.env)
    env.update(ctx.attr.env)
    if toolchain.version.startswith("jruby"):
        java_toolchain = ctx.toolchains["@bazel_tools//tools/jdk:runtime_toolchain_type"]
        tools.extend(java_toolchain.java_runtime.files.to_list())
        env.update({
            "JARS_SKIP": "true",  # Avoid installing extra dependencies.
            "JAVA_HOME": java_toolchain.java_runtime.java_home,
        })

    if _is_windows(ctx):
        script = ctx.actions.declare_file("bundle_install_{}.cmd".format(ctx.label.name))
        template = ctx.file._bundle_install_cmd_tpl
        path = ctx.attr.env.get("PATH", "%PATH%")
        env.update({"PATH": _normalize_path(ctx, toolchain.ruby.dirname) + ";" + path})
    else:
        script = ctx.actions.declare_file("bundle_install_{}.sh".format(ctx.label.name))
        template = ctx.file._bundle_install_sh_tpl
        path = ctx.attr.env.get("PATH", "$PATH")
        env.update({"PATH": toolchain.ruby.dirname + ":" + path})

    # Calculate relative location between BUNDLE_GEMFILE and BUNDLE_PATH.
    relative_dir = "../../"
    for _ in ctx.file.gemfile.short_path.split("/")[2:-1]:
        relative_dir += "../"

    # See https://bundler.io/v2.5/man/bundle-config.1.html for confiugration keys.
    env.update({
        "BUNDLE_BIN": "/".join([relative_dir, binstubs.path]),
        "BUNDLE_DEPLOYMENT": "1",
        "BUNDLE_DISABLE_SHARED_GEMS": "1",
        "BUNDLE_DISABLE_VERSION_CHECK": "1",
        "BUNDLE_GEMFILE": _normalize_path(ctx, ctx.file.gemfile.path),
        "BUNDLE_IGNORE_CONFIG": "1",
        "BUNDLE_PATH": _normalize_path(ctx, "/".join([relative_dir, bundle_path.path])),
        "BUNDLE_SHEBANG": _normalize_path(ctx, toolchain.ruby.short_path),
    })

    ctx.actions.expand_template(
        template = template,
        output = script,
        substitutions = {
            "{env}": _convert_env_to_script(ctx, env),
            "{bundler_exe}": _normalize_path(ctx, bundler_exe),
            "{ruby_path}": _normalize_path(ctx, toolchain.ruby.path),
        },
    )

    ctx.actions.run(
        executable = script,
        inputs = depset([ctx.file.gemfile, ctx.file.gemfile_lock] + ctx.files.srcs + ctx.files.gems),
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
    ] + ctx.files.srcs

    return [
        DefaultInfo(
            files = depset(files),
            runfiles = ctx.runfiles(files),
        ),
        RubyFilesInfo(
            binary = None,
            transitive_srcs = depset([ctx.file.gemfile, ctx.file.gemfile_lock] + ctx.files.srcs),
            transitive_deps = depset(),
            transitive_data = depset(),
            bundle_env = {},
        ),
        BundlerInfo(
            bin = binstubs,
            env = ctx.attr.env,
            gemfile = ctx.file.gemfile,
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
        "srcs": attr.label_list(
            allow_files = True,
            doc = "List of Ruby source files used to build the library.",
        ),
        "env": attr.string_dict(
            doc = "Environment variables to use during installation.",
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
