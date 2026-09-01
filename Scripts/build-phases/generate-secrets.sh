#!/usr/bin/env bash

set -euo pipefail

# Xcode build phases have access to a different PATH than the host.
# So, we need to explicitly add a8c-secrets' default install location to the PATH.
export PATH="$HOME/.local/bin:$PATH"

# Materialize the demo app's Secrets.swift into DerivedData so the decrypted
# credentials never land in the repo checkout.
#
# The compiled file comes from one of two sources, in order:
#
#   1. The a8c-secrets decrypted tree, for internal contributors. The phase runs
#      the decrypt command itself so that secrets are always up to date, and
#      fails the build when it can't.
#   2. Demo/Demo/Secrets.external-contributors.swift — gitignored, so external
#      contributors can copy Demo/Demo/Secrets.template.swift there and add
#      their credentials there with little-to-no-risk of them leaking.

TEMPLATE="${SRCROOT}/Demo/Secrets.template.swift"
EXTERNAL="${SRCROOT}/Demo/Secrets.external-contributors.swift"
DESTINATION="${SCRIPT_OUTPUT_FILE_0}"

mkdir -p "$(dirname "$DESTINATION")"

apply() {
    echo "Applying secrets from ${1}"
    cp "$1" "$DESTINATION"
    exit 0
}

if command -v a8c-secrets >/dev/null 2>&1; then
    a8c-secrets decrypt --non-interactive >/dev/null \
        || { echo "error: 'a8c-secrets decrypt --non-interactive' failed."; exit 1; }

    # Keep the substitution in an assignment: inside `apply "$(...)"` its exit
    # status would be discarded and a decrypt that produced nothing would fall
    # through to the external-contributor branch.
    SECRETS_FILE_NAME="Secrets.swift"
    SECRETS_FILE=$(a8c-secrets which "$SECRETS_FILE_NAME") \
        || { echo "error: 'a8c-secrets which $SECRETS_FILE_NAME' failed."; exit 1; }

    apply "$SECRETS_FILE"
fi

if [ -f "$EXTERNAL" ]; then
    apply "$EXTERNAL"
fi

echo "error: No secrets found! Internal contributors: Install a8c-secrets and follow its set up instructions; see https://github.com/Automattic/a8c-secrets. External contributors: copy '${TEMPLATE}' to '${EXTERNAL}' and fill in your own credentials."
exit 1
