@echo off
setlocal enabledelayedexpansion

{env}

if "{has_git_gem_srcs}"=="1" (
    set "BUNDLE_CACHE_PATH=%TEMP%\bundle-cache-%RANDOM%"
    mkdir "!BUNDLE_CACHE_PATH!"
    echo Detected installing gems from Git, creating temporary Bundler cache in !BUNDLE_CACHE_PATH! ...
    {ruby_path} {sync_bundle_cache_path} "!BUNDLE_GEMFILE!\..\vendor\cache" "!BUNDLE_CACHE_PATH!"
)

{ruby_path} {bundler_exe} install --standalone --local

if defined BUNDLE_CACHE_PATH (
    rmdir /s /q "!BUNDLE_CACHE_PATH!" 2>nul
)

:: vim: ft=dosbatch
