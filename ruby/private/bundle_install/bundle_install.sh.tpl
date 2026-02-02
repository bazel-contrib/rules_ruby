#!/usr/bin/env bash

{env}

{ruby_path} {bundler_exe} install --standalone --local
{ruby_path} {bundler_exe} binstubs --all

# vim: ft=bash
