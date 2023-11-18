#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Set by GH actions, see
# https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables
TAG=${GITHUB_REF_NAME}
# The prefix is chosen to match what GitHub generates for source archives
PREFIX="rules_ruby-${TAG:1}"
ARCHIVE="rules_ruby-$TAG.tar.gz"

# NB: configuration for 'git archive' is in /.gitattributes
git archive --format=tar --prefix=${PREFIX}/ ${TAG} | gzip > $ARCHIVE
SHA=$(shasum -a 256 $ARCHIVE | awk '{print $1}')

# The stdout of this program will be used as the top of the release notes for this release.
cat << EOF
## Using Bzlmod with Bazel 6

TODO: https://github.com/p0deje/rules_ruby/issues/12

## Using WORKSPACE

Paste this snippet into your \`WORKSPACE.bazel\` file:

\`\`\`starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "rules_ruby",
    sha256 = "${SHA}",
    strip_prefix = "${PREFIX}",
    url = "https://github.com/p0deje/rules_ruby/releases/download/${TAG}/${ARCHIVE}",
)
\`\`\`
EOF
