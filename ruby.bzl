# common {{{1
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


# }}} rb_library {{{1

def _rb_library_impl(ctx):
    transitive_srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps)
    return [RubyFiles(transitive_srcs = transitive_srcs)]

rb_library = rule(
    implementation = _rb_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
    }
)

# }}} rb_binary {{{1

_SH_SCRIPT = "{binary} {args}"

# We have to explicitly set PATH on Windows because bundler
# binstubs rely on calling Ruby available globally.
# https://github.com/rubygems/rubygems/issues/3381#issuecomment-645026943

_CMD_BINARY_SCRIPT = """
@set PATH={toolchain_bindir};%PATH%
@call {binary}.cmd {args}
"""

# Calling ruby.exe directly throws strange error so we rely on PATH instead.

_CMD_RUBY_SCRIPT = """
@set PATH={toolchain_bindir};%PATH%
@ruby {args}
"""

def _rb_binary_impl(ctx):
    windows_constraint = ctx.attr._windows_constraint[platform_common.ConstraintValueInfo]
    is_windows = ctx.target_platform_has_constraint(windows_constraint)
    toolchain = ctx.toolchains["@rules_ruby//:toolchain_type"]

    if ctx.attr.bin:
        binary = ctx.executable.bin
    else:
        binary = toolchain.ruby

    binary_path = binary.path
    toolchain_bindir = toolchain.bindir
    if is_windows:
        binary_path = binary_path.replace('/', '\\')
        script = ctx.actions.declare_file("{}.rb.cmd".format(ctx.label.name))
        toolchain_bindir = toolchain_bindir.replace('/', '\\')
        if ctx.attr.bin:
            template = _CMD_BINARY_SCRIPT
        else:
            template = _CMD_RUBY_SCRIPT
    else:
        script = ctx.actions.declare_file("{}.rb".format(ctx.label.name))
        template = _SH_SCRIPT

    ctx.actions.write(
        output = script,
        content = template.format(
            args = " ".join(ctx.attr.args),
            binary = binary_path,
            toolchain_bindir = toolchain_bindir
        )
    )

    transitive_srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps)
    runfiles = ctx.runfiles(transitive_srcs.to_list() + [binary])

    return [DefaultInfo(executable = script, runfiles = runfiles)]

rb_binary = rule(
    implementation = _rb_binary_impl,
    executable = True,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
        "bin": attr.label(
            executable = True,
            allow_single_file = True,
            cfg = "exec",
        ),
        "_windows_constraint": attr.label(
            default = "@platforms//os:windows"
        ),
    },
    toolchains = ["@rules_ruby//:toolchain_type"],
)

# }}} rb_test {{{1

rb_test = rule(
    implementation = _rb_binary_impl,
    test = True,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
        "bin": attr.label(
            executable = True,
            allow_single_file = True,
            cfg = "exec",
        ),
        "_windows_constraint": attr.label(
            default = "@platforms//os:windows"
        ),
    },
    toolchains = ["@rules_ruby//:toolchain_type"],
)

# }}} rb_gem {{{1

def _rb_gem_impl(ctx):
    gem_builder = ctx.actions.declare_file("{}_gem_builder.rb".format(ctx.label.name))
    inputs = get_transitive_srcs(ctx.files.srcs + [gem_builder], ctx.attr.deps)
    toolchain = ctx.toolchains["@rules_ruby//:toolchain_type"]

    # Inputs manifest is a dictionary where:
    #   - key is a path where a file is available (https://bazel.build/rules/lib/File#path)
    #   - value is a path where a file should be (https://bazel.build/rules/lib/File#short_path)
    # They are the same for source inputs, but different for generated ones.
    # We need to make sure that gem builder script copies both correctly, e.g.:
    #   {
    #     "rb/Gemfile": "rb/Gemfile",
    #     "bazel-out/darwin_arm64-fastbuild/bin/rb/LICENSE": "rb/LICENSE",
    #   }
    inputs_manifest = {}
    for src in inputs.to_list():
        inputs_manifest[src.path] = src.short_path

    ctx.actions.expand_template(
        template = ctx.file._gem_builder_tpl,
        output = gem_builder,
        substitutions = {
            "{bazel_out_dir}": ctx.outputs.gem.dirname,
            "{gem_filename}": ctx.outputs.gem.basename,
            "{gemspec}": ctx.file.gemspec.path,
            "{inputs_manifest}": json.encode(inputs_manifest)
        },
    )

    args = ctx.actions.args()
    args.add(gem_builder)
    ctx.actions.run(
        inputs = inputs,
        executable = toolchain.ruby,
        arguments = [args],
        outputs = [ctx.outputs.gem],
    )

rb_gem = rule(
    _rb_gem_impl,
    attrs = {
        "gemspec": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
        "_gem_builder_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//:gem_builder.rb.tpl",
        ),
    },
    outputs = {
        "gem": "%{name}.gem",
    },
    toolchains = ["@rules_ruby//:toolchain_type"],
)

# }}} rb_bundle {{{1

def _rb_bundle_impl(repository_ctx):
    binstubs_path = repository_ctx.path('bin')
    workspace_root = repository_ctx.path(repository_ctx.attr.gemfile).dirname

    if repository_ctx.os.name.startswith("windows"):
        bundle = repository_ctx.path(Label("@rules_ruby_dist//:dist/bin/bundle.cmd"))
        ruby = repository_ctx.path(Label("@rules_ruby_dist//:dist/bin/ruby.exe"))
    else:
        bundle = repository_ctx.path(Label("@rules_ruby_dist//:dist/bin/bundle"))
        ruby = repository_ctx.path(Label("@rules_ruby_dist//:dist/bin/ruby"))

    repository_ctx.template(
        "BUILD",
        repository_ctx.attr._build_tpl,
        executable = False
    )

    repository_ctx.report_progress("Running bundle install")
    result = repository_ctx.execute(
        [
            bundle,
            "install",
        ],
        environment = {
            "BUNDLE_BIN": repr(binstubs_path),
            "BUNDLE_SHEBANG": repr(ruby),
        },
        working_directory = repr(workspace_root),
    )

    if result.return_code != 0:
        fail("%s\n%s" % (result.stdout, result.stderr))

rb_bundle = repository_rule(
    implementation = _rb_bundle_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "gemfile": attr.label(allow_single_file = True),
        "_build_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//:bundle.BUILD.tpl",
        ),
    },
)

# }}} rb_download {{{1

def rb_download(version):
    _rb_download(
        name = "rules_ruby_dist",
        version = version
    )
    native.register_toolchains("@rules_ruby_dist//:toolchain")

def _rb_download_impl(repository_ctx):
    if repository_ctx.os.name.startswith("windows"):
        repository_ctx.report_progress("Downloading RubyInstaller")
        repository_ctx.download(
            url = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-%s-1/rubyinstaller-devkit-%s-1-x64.exe" % (repository_ctx.attr.version, repository_ctx.attr.version),
            output = "ruby-installer.exe"
        )

        repository_ctx.report_progress("Installing Ruby")
        result = repository_ctx.execute([
            "./ruby-installer.exe",
            "/components=ruby,msys2",
            "/dir=dist",
            "/tasks=nomodpath,noassocfiles",
            "/verysilent",
        ])
    else:
        repository_ctx.report_progress("Downloading ruby-build")
        repository_ctx.download_and_extract(
            url = "https://github.com/rbenv/ruby-build/archive/refs/tags/v%s.tar.gz" % repository_ctx.attr._ruby_build_version,
            output = "ruby-build",
            stripPrefix = "ruby-build-%s" % repository_ctx.attr._ruby_build_version
        )

        repository_ctx.report_progress("Installing Ruby")
        result = repository_ctx.execute(["ruby-build/bin/ruby-build", repository_ctx.attr.version, "dist"])

    if result.return_code != 0:
        fail("%s\n%s" % (result.stdout, result.stderr))

    repository_ctx.template(
        "BUILD",
        repository_ctx.attr._build_tpl,
        executable = False,
        substitutions = {
            "{bindir}": repr(repository_ctx.path("dist/bin"))
        }
    )

_rb_download = repository_rule(
    implementation = _rb_download_impl,
    attrs = {
        "version": attr.string(
            mandatory = True,
        ),
        "_ruby_build_version": attr.string(
            default = "20221026",
        ),
        "_build_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//:toolchain.BUILD.tpl",
        )
    }
)

# }}} rb_toolchain {{{1

def rb_toolchain(name, ruby, bundle, bindir):
    toolchain_name = "%s_toolchain" % name

    _rb_toolchain(
        name = toolchain_name,
        ruby = ruby,
        bundle = bundle,
        bindir = bindir,
    )

    native.toolchain(
        name = name,
        toolchain = ":%s" % toolchain_name,
        toolchain_type = "@rules_ruby//:toolchain_type",
    )

def _rb_toolchain_impl(ctx):
    return platform_common.ToolchainInfo(
        ruby = ctx.executable.ruby,
        bundle = ctx.executable.bundle,
        bindir = ctx.attr.bindir
    )

_rb_toolchain = rule(
    implementation = _rb_toolchain_impl,
    attrs = {
        "ruby": attr.label(
            doc = "`ruby` binary to execute",
            allow_files = True,
            executable = True,
            cfg = "exec",
        ),
        "bundle": attr.label(
            doc = "`bundle` to execute",
            allow_files = True,
            executable = True,
            cfg = "exec",
        ),
        "bindir": attr.string(
            doc = "Path to Ruby bin/ directory",
        ),
    },
)

# }}}
# vim: foldmethod=marker
