#!/usr/bin/env bash

{env}

# This is required because Bundle tries to normalize the `.gemspec` files
# during `bundle install`, which doesn't play well with sandboxing as the
# `vendor/cache` folder will be read-only.
if [[ "{has_git_gem_srcs}" == "1" ]]; then
    export BUNDLE_CACHE_PATH="$(mktemp -d)"
    trap 'rm -rf "$BUNDLE_CACHE_PATH"' EXIT
    echo "Detected installing gems from Git, creating temporary Bundler cache in $BUNDLE_CACHE_PATH ..."
    {ruby_path} {sync_bundle_cache_path} "$(dirname "$BUNDLE_GEMFILE")/vendor/cache" "$BUNDLE_CACHE_PATH"
fi

{ruby_path} {bundler_exe} install --standalone --local

# vim: ft=bash
