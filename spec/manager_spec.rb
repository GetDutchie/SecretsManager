# frozen_string_literal: true

RSpec.describe SecretsManager do
  it "returns the correct version" do
    expect(described_class::VERSION).to eq("1.1.0")
  end

  describe "#new" do
    let(:args) { { client: double() } }

    after { described_class.new(args) }

    it "initializes the nested Manager Class" do
      expect(described_class::Manager).to receive(:new).with(args)
    end
  end

  context "SecretsManager::Cache" do
    describe "#new" do
      after { described_class::Cache.new }

      it "initializes the Concurrent::Map Class" do
        expect(Concurrent::Map).to receive(:new)
      end
    end

    describe "#reset" do
      after { described_class::Cache.new.reset }

      it "initializes the Concurrent::Map Class" do
        expect(Concurrent::Map).to receive(:new).twice
      end
    end

    describe "#set" do
      let(:path) { "#{Faker::Lorem.word}/#{Faker::Lorem.word}" }
      let(:value) { Faker::Lorem.word }
      let(:ttl) { 86400 }

      subject(:secrets_manager) do
        klass = described_class::Cache.new.set(path, value)
        klass.instance_variable_get(:@_cache).values.first
      end

      it "initializes the Concurrent::Map Class" do
        expect(Concurrent::Map).to receive(:new).twice.and_call_original
        secrets_manager
      end

      it "returns the cached parameter value" do
        expect(secrets_manager[:value]).to eq(value)
      end

      it "returns the cached parameter ttl" do
        expect(secrets_manager[:expires_at]).to eq(Time.now + ttl)
      end
    end

    describe "#find" do
      pending
    end
  end

  context "SecretsManager::Manager" do
    describe "#secret_env" do
      let(:value) { Faker::Lorem.word }

      context "when ENV AWS_SECRETS_ENV" do
        subject(:secret_env) { described_class::Manager.new.secret_env }

        before do
          ENV['AWS_SECRETS_ENV_TMP'] = ENV['AWS_SECRETS_ENV'] unless ENV.fetch('AWS_SECRETS_ENV', nil) == nil
          ENV['AWS_SECRETS_ENV'] = value
        end

        after do
          if ENV.fetch('AWS_SECRETS_ENV_TMP', nil) == nil
            ENV['AWS_SECRETS_ENV'] = ENV['AWS_SECRETS_ENV_TMP']
          else
            ENV.delete("AWS_SECRETS_ENV")
          end

          ENV.delete("AWS_SECRETS_ENV_TMP")
        end

        it "returns AWS_SECRETS_ENV" do
          expect(secret_env).to eq(value)
        end
      end

      context "when ENV RACK_ENV" do
        subject(:secret_env) { described_class::Manager.new.secret_env }

        before do
          ENV['AWS_SECRETS_ENV_TMP'] = ENV['AWS_SECRETS_ENV'] unless ENV.fetch('AWS_SECRETS_ENV', nil) == nil
          ENV['RACK_ENV_TMP'] = ENV['RACK_ENV'] unless ENV.fetch('RACK_ENV', nil) == nil
          ENV['RACK_ENV'] = value
        end

        after do
          if ENV.fetch('AWS_SECRETS_ENV_TMP', nil) == nil
            ENV['AWS_SECRETS_ENV'] = ENV['AWS_SECRETS_ENV_TMP']
          else
            ENV.delete("AWS_SECRETS_ENV")
          end

          if ENV.fetch('RACK_ENV_TMP', nil) == nil
            ENV['RACK_ENV'] = ENV['RACK_ENV_TMP']
          else
            ENV.delete("RACK_ENV")
          end

          ENV.delete("AWS_SECRETS_ENV_TMP")
          ENV.delete("RACK_ENV_TMP")
        end

        it "returns RACK_ENV" do
          expect(secret_env).to eq(value)
        end
      end

      context "when default" do
        subject(:secret_env) { described_class::Manager.new.secret_env }

        before do
          ENV['AWS_SECRETS_ENV_TMP'] = ENV['AWS_SECRETS_ENV'] unless ENV.fetch('AWS_SECRETS_ENV', nil) == nil
          ENV['RACK_ENV_TMP'] = ENV['RACK_ENV'] unless ENV.fetch('RACK_ENV', nil) == nil
          ENV.delete("AWS_SECRETS_ENV")
          ENV.delete("RACK_ENV")
        end

        after do
          if ENV.fetch('AWS_SECRETS_ENV_TMP', nil) == nil
            ENV['AWS_SECRETS_ENV'] = ENV['AWS_SECRETS_ENV_TMP']
          end

          if ENV.fetch('RACK_ENV_TMP', nil) == nil
            ENV['RACK_ENV'] = ENV['RACK_ENV_TMP']
          end

          ENV.delete("AWS_SECRETS_ENV_TMP")
          ENV.delete("RACK_ENV_TMP")
        end

        it "returns development" do
          expect(secret_env).to eq("development")
        end
      end
    end

    describe "#client" do
      context "without aws client supplied" do
        let(:aws_secrets_key_value) { Faker::Lorem.word }
        let(:aws_secrets_secret_value) { Faker::Lorem.word }
        let(:aws_credentials_double) { double(Aws::Credentials) }

        subject(:client) { described_class::Manager.new.client }

        before do
          ENV['AWS_SECRETS_KEY_TMP'] = ENV['AWS_SECRETS_KEY'] unless ENV.fetch('AWS_SECRETS_KEY', nil) == nil
          ENV['AWS_SECRETS_SECRET_TMP'] = ENV['AWS_SECRETS_SECRET'] unless ENV.fetch('AWS_SECRETS_SECRET', nil) == nil
          ENV['AWS_SECRETS_KEY'] = aws_secrets_key_value
          ENV['AWS_SECRETS_SECRET'] = aws_secrets_secret_value

          allow(Aws::Credentials).to receive(:new).with(aws_secrets_key_value, aws_secrets_secret_value).and_return(aws_credentials_double)
        end

        after do
          if ENV.fetch('AWS_SECRETS_KEY_TMP', nil) == nil
            ENV['AWS_SECRETS_KEY'] = ENV['AWS_SECRETS_KEY_TMP']
          end

          if ENV.fetch('AWS_SECRETS_SECRET_TMP', nil) == nil
            ENV['AWS_SECRETS_SECRET'] = ENV['AWS_SECRETS_SECRET_TMP']
          end

          ENV.delete("AWS_SECRETS_KEY_TMP")
          ENV.delete("AWS_SECRETS_SECRET_TMP")
        end

        context "without AWS_SECRETS_REGION" do
          let(:configuration) do
            {
              region: "us-east-1",
              credentials: aws_credentials_double
            }
          end

          it "returns client" do
            expect(Aws::SecretsManager::Client).to receive(:new).with(configuration)

            client
          end

          it "sets credentials" do
            expect(Aws::Credentials).to receive(:new).with(aws_secrets_key_value, aws_secrets_secret_value).and_return(aws_credentials_double)

            client
          end
        end

        context "with AWS_SECRETS_REGION" do
          let(:aws_secrets_region_value) { Faker::Lorem.word }
          let(:configuration) do
            {
              region: aws_secrets_region_value,
              credentials: aws_credentials_double
            }
          end

          before do
            ENV['AWS_SECRETS_KEY_TMP'] = ENV['AWS_SECRETS_KEY'] unless ENV.fetch('AWS_SECRETS_KEY', nil) == nil
            ENV['AWS_SECRETS_SECRET_TMP'] = ENV['AWS_SECRETS_SECRET'] unless ENV.fetch('AWS_SECRETS_SECRET', nil) == nil
            ENV['AWS_SECRETS_REGION_TMP'] = ENV['AWS_SECRETS_REGION'] unless ENV.fetch('AWS_SECRETS_REGION', nil) == nil
            ENV['AWS_SECRETS_KEY'] = aws_secrets_key_value
            ENV['AWS_SECRETS_SECRET'] = aws_secrets_secret_value
            ENV['AWS_SECRETS_REGION'] = aws_secrets_region_value

            allow(Aws::Credentials).to receive(:new).with(aws_secrets_key_value, aws_secrets_secret_value).and_return(aws_credentials_double)
          end

          after do
            if ENV.fetch('AWS_SECRETS_KEY_TMP', nil) == nil
              ENV['AWS_SECRETS_KEY'] = ENV['AWS_SECRETS_KEY_TMP']
            end

            if ENV.fetch('AWS_SECRETS_SECRET_TMP', nil) == nil
              ENV['AWS_SECRETS_SECRET'] = ENV['AWS_SECRETS_SECRET_TMP']
            end

            if ENV.fetch('AWS_SECRETS_REGION_TMP', nil) == nil
              ENV['AWS_SECRETS_REGION'] = ENV['AWS_SECRETS_REGION_TMP']
            end

            ENV.delete("AWS_SECRETS_KEY_TMP")
            ENV.delete("AWS_SECRETS_SECRET_TMP")
            ENV.delete("AWS_SECRETS_REGION_TMP")
          end

          it "returns client" do
            expect(Aws::SecretsManager::Client).to receive(:new).with(configuration)

            client
          end

          it "sets credentials" do
            expect(Aws::Credentials).to receive(:new).with(aws_secrets_key_value, aws_secrets_secret_value).and_return(aws_credentials_double)

            client
          end
        end
      end

      context "with aws client supplied" do
        let(:aws_client_double) { double() }

        subject(:client) { described_class::Manager.new(client: aws_client_double).client }

        it "returns aws client" do
          expect(client).to eq(aws_client_double)
        end
      end
    end

    describe "#[]" do
      pending
    end

    describe "#fetch" do
      pending
    end
  end
end
