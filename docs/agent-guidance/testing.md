# Testing

One suite: `spec/manager_spec.rb`, configured by `spec/spec_helper.rb`.

```sh
bundle exec rake spec                                   # whole suite
bundle exec rspec spec/manager_spec.rb -e "returns the correct version"
```

`.rspec` passes `--format documentation --color --require spec_helper`, so specs
do not require `spec_helper` themselves.

## Never use real credentials

Every value in the suite comes from `Faker`, and AWS is always an RSpec double —
either injected through `SecretsManager::Manager.new(client: double)` or stubbed
with `allow_any_instance_of(...).to receive(:client)`. No spec should ever reach
the network or read a real AWS credential. Do not add a spec that requires
`AWS_SECRETS_KEY`/`AWS_SECRETS_SECRET` to hold live values.

## Config that will bite you

- **Time is frozen.** `spec_helper` calls `Timecop.freeze` in a global `before`
  and `Timecop.return` in `after`. That is why assertions can compare against
  `Time.now + ttl` exactly. Any test relying on time actually elapsing must
  advance the clock through Timecop, not `sleep`.
- **`focus` silently narrows the run.** `config.filter_run focus: true` with
  `run_all_when_everything_filtered = true` means a stray `focus: true` tag makes
  the suite run only that example while still exiting green. Never commit one.
- **Monkey patching is off** (`disable_monkey_patching!`) — use `RSpec.describe`,
  not bare `describe`.
- Failures persist to `.rspec_status` (gitignored), enabling `--only-failures`.

## The client-injection seam

`Manager#client` returns the injected client if one was passed, otherwise builds
an `Aws::SecretsManager::Client` from `AWS_SECRETS_REGION` (default `us-east-1`),
`AWS_SECRETS_KEY`, and `AWS_SECRETS_SECRET`. Prefer injection over stubbing when
adding specs; it is the cheaper and more stable seam.

## ENV manipulation

Specs that exercise `secret_env` or `client` mutate process ENV and restore it in
`after` hooks using `*_TMP` shadow variables. If you add a spec touching ENV,
follow the same save/restore shape so ordering stays independent — several of the
existing restore branches are subtle, so copy an adjacent block rather than
improvising.

## Version coupling

The first example asserts `described_class::VERSION` against a hard-coded string.
Any version bump must update `spec/manager_spec.rb` too — see
[release.md](release.md).
