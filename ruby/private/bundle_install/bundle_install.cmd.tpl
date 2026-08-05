@echo off

{env}

{ruby_path} {bundler_exe} install --standalone --local {extra_args}
{ruby_path} {bundler_exe} binstubs --all

:: vim: ft=dosbatch
