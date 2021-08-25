# frozen_string_literal: true

RSpec.describe SecretsManager do
  it "returns the correct version" do
    expect(described_class::VERSION).to eq("1.2.0")
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
      let(:path) { "TEST/PATH" }
      let(:value) { "TESTVALUE" }
      let(:ttl) { 86400 }

      subject(:secrets_manager) do
        klass = described_class::Cache.new.set(path, value)
        klass.instance_variable_get(:@_cache).values.first
      end

      it "initializes the Concurrent::Map Class" do
        expect(Concurrent::Map).to receive(:new).and_call_original
        secrets_manager
      end

      it "returns the cached parameter value" do
        expect(secrets_manager[:value]).to eq(value)
      end

      it "returns the cached parameter ttl" do
        expect(secrets_manager[:expires_at]).to eq(Time.now + ttl)
      end
    end

    describe "#find", focus: true do
      pending
    end
  end

  context "SecretsManager::Manager" do
    describe "#secret_env" do
      pending
    end

    describe "#client" do
      pending
    end

    describe "#fetch" do
      pending
    end

    describe "#[]" do
      pending
    end
  end
end
