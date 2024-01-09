#!/usr/bin/env bash

{env}

{gem_binary} \
  install \
  {gem} \
  --wrappers \
  --ignore-dependencies \
  --local \
  --no-document \
  --no-env-shebang \
  --install-dir {install_dir} \
  --bindir {install_dir}/bin

# vim: ft=bash
