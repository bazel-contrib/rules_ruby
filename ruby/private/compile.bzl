"""Helper for compiling Ruby sources to bytecode"""

def to_runfiles_path(ctx, file):
    """Converts a File to its runfiles path string.

    Args:
        ctx: Rule context
        file: File object

    Returns:
        Runfiles path string (e.g., "_main/lib/foo.rb" or "repo_name/path/to/file.rb")
    """
    if file.short_path.startswith("../"):
        # External file - short_path already includes repo name
        return file.short_path[3:]  # Remove "../" prefix
    else:
        # Workspace file - prepend workspace name
        return ctx.workspace_name + "/" + file.short_path

def compile_ruby_sources(ctx, srcs, ruby_toolchain, compile_script):
    """Creates actions to compile Ruby sources to bytecode.

    Args:
        ctx: Rule context
        srcs: List of .rb source Files
        ruby_toolchain: Ruby toolchain info
        compile_script: File object for the compile.rb script

    Returns:
        Dict mapping source runfiles path (string) to bytecode File
    """
    mappings = {}

    for src in srcs:
        # Only compile .rb files
        if not src.path.endswith(".rb"):
            continue

        # Declare .rbc output file in same relative location
        output_path = src.basename + "c"
        bytecode_file = ctx.actions.declare_file(output_path)

        # Create compilation action
        ctx.actions.run(
            executable = ruby_toolchain.ruby,
            arguments = [compile_script.path, src.path, bytecode_file.path],
            inputs = [src, compile_script],
            outputs = [bytecode_file],
            mnemonic = "RubyCompile",
            progress_message = "Compiling %s to bytecode" % src.short_path,
        )

        # Map source runfiles path to bytecode file
        source_runfiles_path = to_runfiles_path(ctx, src)
        mappings[source_runfiles_path] = bytecode_file

    return mappings
