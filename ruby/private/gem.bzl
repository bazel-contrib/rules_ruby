load("//ruby/private:providers.bzl", "get_transitive_srcs")

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
            "{inputs_manifest}": json.encode(inputs_manifest),
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
            default = "@rules_ruby//ruby/private:gem/gem_builder.rb.tpl",
        ),
    },
    outputs = {
        "gem": "%{name}.gem",
    },
    toolchains = ["@rules_ruby//:toolchain_type"],
)
