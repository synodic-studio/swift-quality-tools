# Fixtures

Deliberately-broken sample Swift files used to exercise the custom rules by hand.
Every file here is *supposed* to trip one or more rules — they are inputs, not
production code.

This directory is excluded in `.swiftlint.yml` (both the standard linter and the
custom engine read that `excluded:` list), so running the tool on its own repo
stays green. Do not "fix" the violations in these files; that defeats their purpose.

Automated coverage of the rules lives in `Tests/SharedUtilitiesTests/` (Swift Testing).
