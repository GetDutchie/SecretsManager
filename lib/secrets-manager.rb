# frozen_string_literal: true

require "version"
require "aws-sdk-secretsmanager"
require "concurrent-ruby"
require "json"

module SecretsManager
  class SecretNotFound < StandardError; end;

  def self.new(**args)
    Manager.new(**args)
  end

  class Cache
    def initialize
      @_cache = Concurrent::Map.new
    end

    def reset
      @_cache = Concurrent::Map.new
    end

    def set(path, value, ttl = 86400)
      @_cache[path] = {expires_at: (Time.now + ttl), value: value}
      return self
    end

    def find(path)
      fetched = @_cache[path]
      return unless fetched
      return unless !fetched[:expires_at].nil? && (fetched[:expires_at]) > Time.now
      fetched[:value]
    end
  end

  class Manager
    attr_reader :cache

    def initialize(client: nil)
      @cache = Cache.new
      @aws_client = client
    end

    def secret_env
      ENV['AWS_SECRETS_ENV'] || ENV['RACK_ENV'] || dev
    end

    def client
      return @aws_client if @aws_client

      @_client ||= Aws::SecretsManager::Client.new({
        region: ENV.fetch('AWS_SECRETS_REGION', 'us-east-1'),
        credentials: Aws::Credentials.new(ENV['AWS_SECRETS_KEY'], ENV['AWS_SECRETS_SECRET'])
      })
    end

    def fetch(secret_path)
      resolved_path = secret_env + '/' + secret_path

      cached_value = cache.find(resolved_path)
      return cached_value if cached_value

      response = client.get_secret_value(secret_id: resolved_path)
      return nil unless response && response.secret_string
      object = JSON.parse(response.secret_string, symbolize_names: true)

      value = parse_value(object)
      set_in_memory(resolved_path, value, parse_ttl(object))
      return value
    rescue Aws::SecretsManager::Errors::ResourceNotFoundException => e
      raise SecretsManager::SecretNotFound, "Could not find secret with path #{resolved_path}"
    end

    def [](path)
      fetch(path)
    end

    private
    def parse_ttl(data)
      ## Default to one day cache TTL
      return 86400 unless data[:ttl].present?
      data[:ttl].to_i
    end

    def parse_value(data)
      value = data[:value]

      if data[:encoding].present?
        case data[:encoding]
        when "base64"
          value = Base64.strict_decode64(value)
        end
      end

      return value
    end

  end
end