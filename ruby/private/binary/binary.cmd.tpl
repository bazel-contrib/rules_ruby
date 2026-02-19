@echo off
setlocal enableextensions enabledelayedexpansion

set RUNFILES_MANIFEST_ONLY=1
{rlocation_function}

:: Find location of Ruby in runfiles.
call :rlocation {ruby} ruby
for %%a in ("!ruby!\..") do set PATH=%%~fa;%PATH%

:: Find location of JAVA_HOME in runfiles.
if "{java_bin}" neq "" (
  call :rlocation {java_bin} java_bin
  for %%a in ("!java_bin!\..\..") do set JAVA_HOME=%%~fa
)

:: Bundler expects the %HOME% directory to be writable and produces misleading
:: warnings if it isn't. This isn't the case in every situation (e.g. remote
:: execution) and Bazel recommends using %TEST_TMPDIR% when it's available:
:: https://bazel.build/reference/test-encyclopedia#initial-conditions
::
:: We set %HOME% prior to setting environment variables from the target itself
:: so that users can override this behavior if they desire.
if defined TEST_TMPDIR (
  set "HOME=%TEST_TMPDIR%"
)

:: Set environment variables.
{env}

:: Find location of Bundle path in runfiles.
if "{bundler_command}" neq "" (
  call :rlocation "!BUNDLE_GEMFILE!" BUNDLE_GEMFILE
  call :rlocation "!BUNDLE_PATH!" BUNDLE_PATH
  if defined JARS_HOME (
    call :rlocation "!JARS_HOME!" JARS_HOME
    if "{jars_home_strip_suffix}" neq "" (
      set "JARS_HOME=!JARS_HOME:{jars_home_strip_suffix}=!"
    )
  )
)

{bundler_command} {ruby_binary_name} {binary} {args} %*

:: vim: ft=dosbatch
