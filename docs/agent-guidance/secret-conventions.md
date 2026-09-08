# Secret path, payload, and cache conventions

Read this before changing `Manager#fetch`, `#parse_value`, `#parse_ttl`, or the
`Cache` class in `lib/secrets-manager.rb`. These conventions are a public
contract — consumers' secrets are already stored in AWS under this layout.

## Path resolution

Format in AWS: `{{secret_env}}/{{secret_path}}`. Callers omit `secret_env`.

```ruby
$secrets.fetch('twilio-key')   # reads dev/twilio-key when secret_env == "dev"
$secrets['services/twilio/api-key']  # #[] is an alias for #fetch
```

A path that `start_with?("global")` is passed through unmodified, so a secret
shared across environments is stored and read as `global/config/foo`:

```ruby
$secrets.fetch('global/config/foo')  # reads global/config/foo
```

`secret_env` resolves in order: `AWS_SECRETS_ENV`, then `RACK_ENV`, then the
literal `"development"`. Typical values: `dev`, `staging`, `qa`, `production`.

## Payload format

The secret's value stored in AWS must be a JSON object. Only `value` is required.

| Key | Meaning |
| --- | --- |
| `value` | the secret itself (required) |
| `ttl` | in-memory cache lifetime in seconds; defaults to `86400` when absent |
| `encoding` | only `base64` is handled — decoded via `Base64.strict_decode64` |
| `type` | only `json` is handled — parsed with `symbolize_names: true` |

Order matters: `parse_value` decodes `encoding` **first**, then applies `type`.
A base64-encoded JSON blob therefore round-trips correctly.

```json
{"value": "secretvalue", "ttl": 60}
{"value": "c2VjcmV0dmFsdWU=", "ttl": 60, "encoding": "base64"}
```

Unrecognized `encoding`/`type` values fall through the `case` and leave the
value untouched — there is no error for an unknown option.

## Caching

`Cache` wraps a `Concurrent::Map` keyed by the **resolved** path (i.e. including
the env or `global` prefix), storing `{expires_at:, value:}`. `find` returns
`nil` for both a missing entry and an expired one, which makes a stale read
indistinguishable from a miss — that is intentional, since a miss just re-fetches.

The cache is per-`Manager` instance. Construct the manager once at boot and hold
it in a constant or global (`$secrets = SecretsManager.new`); constructing one
per call silently defeats caching and multiplies AWS calls.

## Errors

`Aws::SecretsManager::Errors::ResourceNotFoundException` is translated to
`SecretsManager::SecretNotFound`, whose message includes the resolved path.
Do not add the secret value to any error message or log line. Other AWS errors
propagate unwrapped.

A response that is nil or has a nil `secret_string` returns `nil` without
caching or raising.
