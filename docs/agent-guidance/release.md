# Releasing

`secrets-manager` is a public gem on rubygems.org. Releasing is **irreversible**:
`rake release` pushes a git tag, pushes commits, and publishes the `.gem`.
Never run it without explicit human approval for that specific version.

## Steps

1. Bump `VERSION` in `lib/version.rb`.
2. Update the matching assertion in `spec/manager_spec.rb` (it compares
   `described_class::VERSION` to a literal string — the suite fails otherwise).
3. Add an entry to `CHANGELOG.md`, newest version at the top, bullets describing
   user-visible changes (see the existing `1.1.0` entry for the shape).
4. `bundle install` so `Gemfile.lock` records the new version of the path gem.
5. `bundle exec rake spec` — must be green.
6. With approval: `bundle exec rake release`.

`bundle exec rake install` builds and installs locally without publishing; use it
to verify packaging first.

## What ships

`secrets-manager.gemspec` builds the file list from `git ls-files`, excluding
`test/`, `spec/`, and `features/`. Consequences:

- Untracked files are **not** packaged, even if present locally.
- A new runtime file must be committed before it will ship.
- Never `git add` a file containing real credentials — beyond the usual risk, the
  gemspec would package it into a public release.

Runtime dependencies are `concurrent-ruby`, `aws-sdk-secretsmanager`, and
`activesupport ~> 5.0`. Widening or bumping these affects every consumer; treat
it as a breaking-risk change and call it out in the changelog.

## Metadata

`homepage_uri`, `source_code_uri`, and `changelog_uri` in the gemspec all point at
`GetDutchie/SecretsManager` on the `master` branch. Keep `master` as the released
branch and do not force-push it — published gem metadata links into its history.
