"Helpers to get location of files in runfiles. Vendored from aspect_bazel_lib"

# https://github.com/aspect-build/bazel-lib/blob/ddac9c46c3bff4cf8d0118a164c75390dbec2da9/lib/paths.bzl
BASH_RLOCATION_FUNCTION = r"""
# --- begin runfiles.bash initialization v2 ---
set -uo pipefail; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
source "$0.runfiles/$f" 2>/dev/null || \
source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
{ echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v2 ---
"""

# https://github.com/aspect-build/bazel-lib/blob/ddac9c46c3bff4cf8d0118a164c75390dbec2da9/lib/windows_utils.bzl
BATCH_RLOCATION_FUNCTION = r"""
rem Usage of rlocation function:
rem        call :rlocation <runfile_path> <abs_path>
rem        The rlocation function maps the given <runfile_path> to its absolute
rem        path and stores the result in a variable named <abs_path>.
rem        This function fails if the <runfile_path> doesn't exist in mainifest
rem        file.
:: Start of rlocation
goto :rlocation_end
:rlocation
if "%~2" equ "" (
  echo>&2 ERROR: Expected two arguments for rlocation function.
  exit 1
)
if "%RUNFILES_MANIFEST_ONLY%" neq "1" (
  set %~2=%~1
  exit /b 0
)
if exist "%RUNFILES_DIR%" (
  set RUNFILES_MANIFEST_FILE=%RUNFILES_DIR%_manifest
)
if "%RUNFILES_MANIFEST_FILE%" equ "" (
  set RUNFILES_MANIFEST_FILE=%~f0.runfiles\MANIFEST
)
if not exist "%RUNFILES_MANIFEST_FILE%" (
  set RUNFILES_MANIFEST_FILE=%~f0.runfiles_manifest
)
set MF=%RUNFILES_MANIFEST_FILE:/=\%
if not exist "%MF%" (
  echo>&2 ERROR: Manifest file %MF% does not exist.
  exit 1
)
set runfile_path=%~1
set abs_path=
for /F "tokens=2* usebackq" %%i in (`%SYSTEMROOT%\system32\findstr.exe /l /c:"!runfile_path! " "%MF%"`) do (
  set abs_path=%%i
)
:: There should be a way to locate the fully resolved path to a file in runfiles
:: because the manifest doesn't contain paths to files in directories. This prevents
:: finding Bundler-generated binstubs (runfiles manifest has only `bin/private` record).
:: It works fine on runfiles.bash, so it's a matter of making a better batch script that
:: handles all the cases. PRs are welcome but current Ruby ruleset maintainers don't 
:: have enough Windows scripting knowledge. Below is a naive attempt to make it work
:: but it fails in certain cases, so this functionality is completely disabled.
::
:: if "!abs_path!" equ "" (
::   if exist %~f0.runfiles\!runfile_path:/=\! (
::     set pshpath=%~f0.runfiles\!runfile_path:/=\!
::     for /f %%A in ('powershell -Command "Get-Item -LiteralPath \"!pshpath!\" | Get-ItemProperty | Select-Object -ExpandProperty Target"') do (
::       set abs_path=%%A
::       set abs_path=!abs_path:\=/!
::     )
::   )
:: )
if "!abs_path!" equ "" (
  echo>&2 ERROR: !runfile_path! not found in runfiles manifest
  exit 1
)
set %~2=!abs_path!
exit /b 0
:rlocation_end
:: End of rlocation
"""

def is_windows(ctx):
    windows_constraint = ctx.attr._windows_constraint[platform_common.ConstraintValueInfo]
    return ctx.target_platform_has_constraint(windows_constraint)

def convert_env_to_script(ctx, env):
    """Converts an env dictionary to a string of batch/shell commands.

    Args:
        ctx: rule context
        env: dictionary of environment variables

    Returns:
        a string with export environment variables commands.
    """
    environment = []
    if is_windows(ctx):
        export_command = "set"
    else:
        export_command = "export"

    for (name, value) in env.items():
        command = "{command} {name}={value}".format(command = export_command, name = name, value = value)
        environment.append(command)

    return "\n".join(environment)

def normalize_path(ctx, path):
    """Converts path to an OS-specific equivalent.

    Args:
        ctx: rule context
        path: filepath string

    Returns:
        an OS-specific path.
    """
    if is_windows(ctx):
        return path.replace("/", "\\")
    else:
        return path.replace("\\", "/")

def join_and_indent(names, indentation_level = 2):
    """Convers a list of strings to a pretty indented BUILD variant.

    Args:
        names: list of strings
        indentation_level: how many 4 spaces to indent with

    Returns:
        indented string
    """
    indentation = ""
    for _ in range(0, indentation_level):
        indentation += "    "

    string = "["
    for name in names:
        string += '\n%s"%s",' % (indentation, name)
    string += "\n%s]" % indentation[:-4]

    return string

def normalize_bzlmod_repository_name(name):
    """Converts Bzlmod repostory to its private name.

    This is needed to define a target that is called the same as the repository.
    For example, given a canonical name "rules_ruby+override+ruby+bundle" or
    "rules_ruby~override~ruby~bundle",
    the function would return "bundle" as the name.

    This is a hacky workaround and will be fixed upstream.
    See https://github.com/bazelbuild/bazel/issues/20486.

    Args:
        name: canonical repository name

    Returns:
        repository name
    """
    if "+" in name:
        return name.rpartition("+")[-1]

    return name.rpartition("~")[-1]

def to_rlocation_path(source):
    """Returns source path that can be used with runfiles library."""
    return source.short_path.removeprefix("../")
