#!/usr/bin/env ruby
# frozen_string_literal: true

# Bazel Ruby Runtime Setup
#
# This file sets up the Bazel runtime environment for Ruby applications.
# It should be required early in the application boot process.
#
# Usage:
#   rules_ruby_setup = ENV["RULES_RUBY_SETUP"]
#   require rules_ruby_setup if rules_ruby_setup

require_relative "bazel_patches"
require_relative "bytecode_loader"
