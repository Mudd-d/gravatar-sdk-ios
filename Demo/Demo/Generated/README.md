# Generated Sources

`Secrets.swift` is shown in red in Xcode and `Open Quickly` cannot find it.
That is expected: it does not exist in the repository.

The `Generate Secrets.swift` build phase writes it into the demo target's `$(DERIVED_FILE_DIR)` when needed, from the secrets managed by `a8c-secrets`, or, missing those, from `Secrets.external-contributors.swift`, which external contributors can create by copying the committed `Secrets.template.swift`.
See `Scripts/build-phases/generate-secrets.sh`.

Do not delete the red reference. The demo app will not compile without it!
