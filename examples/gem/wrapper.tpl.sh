#!/usr/bin/env bash

@@rlocation_lib@@

set -euo pipefail

rake_binary_expansion=(@@rake_binary@@)

echo "calling the rake binary"
rake="$(rlocation @@rake_binary@@)"
rakefile="$(rlocation @@rakefile@@)"
"$rake" -f "$rakefile" goodnight
set -x
eval "$("$rake" -f "$rakefile" goodnight)"
set +x

echo "rake failed to fail"
echo "rlocationpaths for rake binary:"
printf '  %s\n' "${rake_binary_expansion[@]}"
exit 1
