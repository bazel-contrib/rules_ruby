@echo off

{env}

{ruby_path} {bundler_exe} install --standalone --local {extra_args}
{binstubs_cmd}

:: vim: ft=dosbatch
