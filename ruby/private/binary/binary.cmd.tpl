@echo off
setlocal enableextensions enabledelayedexpansion

:: Find location of JAVA_HOME in runfiles.
if "{java_bin}" neq "" (
  {rlocation_function}
  set RUNFILES_MANIFEST_ONLY=1
  call :rlocation {java_bin} java_bin
  for %%a in ("%java_bin%\..\..") do set JAVA_HOME=%%~fa
)

:: Set environment variables.
set PATH={toolchain_bindir};%PATH%
{env}

{bundler_command} {ruby_binary_name} {binary} {args} %*
