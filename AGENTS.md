# SecretsManager — agent guide

Ruby gem (`secrets-manager`) wrapping AWS Secrets Manager with env-scoped secret
paths and an in-memory TTL cache. Published to rubygems.org from this repo.
Source: <https://github.com/GetDutchie/SecretsManager>

Nearly all logic lives in one file: `lib/secrets-manager.rb` (`SecretsManager::Cache`
and `SecretsManager::Manager`). Read it before changing behavior — it is ~120 lines.

## Commands

| Task | Command |
| --- | --- |
| Install deps | `bin/setup` (runs `bundle install`) |
| Run tests | `bundle exec rake spec` (or `rake spec`; `spec` is the default task) |
| Run one spec | `bundle exec rspec spec/manager_spec.rb -e "<example name>"` |
| REPL with gem loaded | `bin/console` |
| Install gem locally | `bundle exec rake install` |
| Release (see below) | `bundle exec rake release` |

Ruby 2.6.3 / bundler 2.0.2 per `.travis.yml`. `.rspec` auto-requires `spec_helper`,
so specs need no explicit require.

## Safety rules

- **Never commit real secret values or AWS credentials.** Specs generate all
  values with `Faker` and stub AWS with RSpec doubles — keep it that way; no
  fixture, spec, or comment should carry a live secret.
- **Never log or print a resolved secret.** `Manager#fetch` returns decoded
  plaintext. The `SecretNotFound` error deliberately interpolates only the
  resolved *path*, never the value (`lib/secrets-manager.rb:82`) — preserve that
  when editing error handling.
- **Credentials come from ENV only** (`AWS_SECRETS_KEY`, `AWS_SECRETS_SECRET`).
  Never hardcode them or add a default fallback.
- **`bundle exec rake release` is irreversible and public** — it tags, pushes
  commits and tags, and publishes the `.gem` to rubygems.org. Never run it
  without explicit human approval on that specific release.
- **Never force-push `master`.** It is the released branch referenced by the
  gemspec's `changelog_uri` and `source_code_uri`.

## Invariants

- `spec/manager_spec.rb:5` asserts the literal version string. Bumping
  `lib/version.rb` **requires** updating that assertion or the suite fails.
- A lookup starting with `global` is used verbatim; anything else is prefixed
  with `secret_env` + `/`. Changing this breaks every consumer's key layout.
- `secret_env` resolves `AWS_SECRETS_ENV` → `RACK_ENV` → `"development"`.
- Cache default TTL is 86400s, applied when the payload omits `ttl`.
- An injected client (`SecretsManager.new(client:)`) always wins over the
  ENV-built AWS client — this is the test seam.
- The gemspec packages files via `git ls-files`; untracked files are never shipped.

## Read when…

| Doc | Read when… |
| --- | --- |
| [docs/agent-guidance/secret-conventions.md](docs/agent-guidance/secret-conventions.md) | touching path resolution, payload parsing (`ttl`/`encoding`/`type`), or caching |
| [docs/agent-guidance/testing.md](docs/agent-guidance/testing.md) | writing or debugging specs — Timecop, ENV save/restore, and `focus` gotchas |
| [docs/agent-guidance/release.md](docs/agent-guidance/release.md) | bumping the version, editing `CHANGELOG.md`, or publishing |
| [README.md](README.md) | you need the consumer-facing usage/config story to keep docs in sync |

## Gotchas

- `lib/` is on the load path, so `lib/secrets-manager.rb` does `require "version"`
  (not a nested path). Keep new requires consistent with that.
- `activesupport` is pulled in only for `Object#blank?` — `parse_ttl` and
  `parse_value` depend on it.
- There is no linter or formatter configured, and `.travis.yml` is the only CI
  config present (it installs bundler but declares no explicit script step).
  Match the surrounding style by hand.
