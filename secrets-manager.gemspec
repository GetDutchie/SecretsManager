lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "version"

Gem::Specification.new do |spec|
  spec.name          = "secrets-manager"
  spec.version       = SecretsManager::VERSION
  spec.authors       = ["Christopher Ostrowski", "Matt Hooks", "Evan Waters"]
  spec.email         = ["chris@dutchie.com", "matt.hooks@dutchie.com", "evan.waters@dutchie.com"]

  spec.summary       = %q{Ruby + AWS Secrets Manager}
  spec.description   = %q{Ruby AWS Secrets Manager interface. Allows for env specific secrets, in-memory caching with custom TTL, file storage, and simple API.}
  spec.homepage      = "https://github.com/GetDutchie/SecretsManager"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/GetDutchie/SecretsManager.git"
  spec.metadata["changelog_uri"] = "https://github.com/GetDutchie/SecretsManager/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "concurrent-ruby", ">= 1.0"
  spec.add_dependency "aws-sdk-secretsmanager", ">= 1.31.0"
  spec.add_dependency "activesupport", ">= 5.0.0.1", "< 8"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.13.1"
  spec.add_development_dependency "timecop", "~> 0.8.1"
  spec.add_development_dependency "faker"
end
