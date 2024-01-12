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

:: Set environment variables.
{env}

:: Find location of Bundle path in runfiles.
if "{bundler_command}" neq "" (
  call :rlocation "!BUNDLE_GEMFILE!" BUNDLE_GEMFILE
  call :rlocation "!BUNDLE_PATH!" BUNDLE_PATH
)

{bundler_command} {ruby_binary_name} {binary} {args} %*

:: vim: ft=dosbatch
