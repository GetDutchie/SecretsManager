# SecretsManager.rb

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'secrets-manager'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install secrets-manager

## Usage

To use this gem, you must have an AWS account and permissions to setup secret values using [Secrets Manager](https://aws.amazon.com/secrets-manager/)

This gem makes assumptions and has requirements about how you should be storing your secrets.

### Path Name
This gem uses the concept of env specific secrets within the same account. While separate AWS accounts can be used to maintain separation, it can be desirable to use a single account.

The path format is as follows: `{{secret_env}}/{{secret_path}}`. When using this gem you would leave the `secret_env` out of your request.

For example, to access the secret `twlio-key`, `$secrets.fetch('twilio-key')`. This would be stored in AWS SM as `dev/twilio-key`.

### Payload
This gem expects your secret value to be a JSON object. The only required key is `value`. The following keys are optional:
* `ttl` - Time to live in seconds. Describes how long the secret should live in in-memory cache.
* `encoding` - Currently, only `base64` is supported as a value. If your `value` is base64 encoded, this will result in a returned secret that is base64 decoded.

Example:
```
{"value": "secretvalue", "ttl": 60} // Will live in cache for 60 seconds.
```

```
{"value": "c2VjcmV0dmFsdWU=", "ttl": 60, "encoding": "base64"} // Will live in cache for 60 seconds and is base64 encoded. Result will be "secretvalue"
```

### Configuration
The follow ENV vars are expected:
* `AWS_SECRETS_ENV` - preceeds all path lookups, ex: `dev`, `staging`, `qa`, `production`
* `AWS_SECRETS_KEY` - AWS IAM access key
* `AWS_SECRETS_SECRET` - AWS IAM access secret

The manager should be created at boot time, in an initializer for example, and stored as a constant or global.
```
$secrets = SecretsManager.new
```

### Lookup
```
$secrets.fetch('services/twilio/api-key')
$secrets['services/twilio/api-key']
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/secrets-manager.
