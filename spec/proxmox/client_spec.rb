# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Proxmox::Client do
  let(:host) { 'proxmox.example.com' }
  let(:token_name) { 'user@pam!mytoken' }
  let(:token_value) { 'secret-token-value' }

  describe '#initialize' do
    context 'with token authentication' do
      it 'creates a client with token credentials' do
        client = described_class.new(
          host: host,
          token_name: token_name,
          token_value: token_value
        )

        expect(client).to be_a(described_class)
      end
    end

    context 'with password authentication' do
      it 'creates a client with username/password credentials' do
        stub_request(:post, 'https://proxmox.example.com:8006/api2/json/access/ticket')
          .with(body: { 'username' => 'user@pam', 'password' => 'secret' })
          .to_return(
            status: 200,
            body: { data: { ticket: 'ticket', CSRFPreventionToken: 'token' } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        client = described_class.new(
          host: host,
          username: 'user@pam',
          password: 'secret'
        )

        expect(client).to be_a(described_class)
      end
    end

    context 'with environment variables' do
      before do
        ENV['PROXMOX_HOST'] = host
        ENV['PROXMOX_TOKEN_NAME'] = token_name
        ENV['PROXMOX_TOKEN_VALUE'] = token_value
        Proxmox.reset_configuration!
      end

      after do
        ENV.delete('PROXMOX_HOST')
        ENV.delete('PROXMOX_TOKEN_NAME')
        ENV.delete('PROXMOX_TOKEN_VALUE')
        Proxmox.reset_configuration!
      end

      it 'creates a client from environment variables' do
        client = described_class.new
        expect(client).to be_a(described_class)
      end
    end

    context 'without credentials' do
      it 'raises an authentication error' do
        expect do
          described_class.new(host: host)
        end.to raise_error(Proxmox::AuthenticationError)
      end
    end
  end

  describe 'resource accessors' do
    let(:client) do
      described_class.new(
        host: host,
        token_name: token_name,
        token_value: token_value
      )
    end

    it 'provides access to cluster resource' do
      expect(client.cluster).to be_a(Proxmox::Resources::Cluster)
    end

    it 'provides access to nodes resource' do
      expect(client.nodes).to be_a(Proxmox::Resources::Node)
    end

    it 'provides access to specific node' do
      node = client.node('pve1')
      expect(node).to be_a(Proxmox::Resources::Node)
    end

    it 'provides access to specific VM' do
      stub_request(:get, 'https://proxmox.example.com:8006/api2/json/nodes/pve1/qemu/100/status/current')
        .to_return(
          status: 200,
          body: { data: { status: 'running' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      stub_request(:get, 'https://proxmox.example.com:8006/api2/json/nodes/pve1/qemu/100/config')
        .to_return(
          status: 200,
          body: { data: { name: 'test-vm' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      vm = client.vm('pve1', 100)
      expect(vm).to be_a(Proxmox::Resources::VM)
    end

    it 'provides access to specific container' do
      container = client.container('pve1', 101)
      expect(container).to be_a(Proxmox::Resources::Container)
    end

    it 'provides access to specific storage' do
      storage = client.storage('pve1', 'local-lvm')
      expect(storage).to be_a(Proxmox::Resources::Storage)
    end
  end
end
