@echo off
setlocal enabledelayedexpansion

{env}

if "{has_git_gem_srcs}" == "1" (
    set "BUNDLE_CACHE_PATH=%TEMP%\bundle-cache-%RANDOM%"
    mkdir "!BUNDLE_CACHE_PATH!"
    set "BUNDLE_CACHE_PATH=!BUNDLE_CACHE_PATH:\=/!"
    echo Detected installing gems from Git, creating temporary Bundler cache in !BUNDLE_CACHE_PATH! ...
    for %%F in ("!BUNDLE_GEMFILE!") do set "GEMFILE_DIR=%%~dpF"
    {ruby_path} {sync_bundle_cache_path} "!GEMFILE_DIR!vendor\cache" "!BUNDLE_CACHE_PATH!"
)

{ruby_path} {bundler_exe} install --standalone --local
set BUNDLE_EXIT=!ERRORLEVEL!

if "{has_git_gem_srcs}" == "1" (
    rmdir /s /q "!BUNDLE_CACHE_PATH!"
)

endlocal & exit /b %BUNDLE_EXIT%
:: vim: ft=dosbatch
