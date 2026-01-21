# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Proxmox::Configuration do
  describe '#initialize' do
    it 'sets default values' do
      config = described_class.new

      expect(config.port).to eq(8006)
      expect(config.verify_ssl).to be true
      expect(config.timeout).to eq(30)
    end

    it 'loads values from environment variables' do
      ENV['PROXMOX_HOST'] = 'test.example.com'
      ENV['PROXMOX_PORT'] = '8007'
      ENV['PROXMOX_VERIFY_SSL'] = 'false'
      ENV['PROXMOX_TIMEOUT'] = '60'

      config = described_class.new

      expect(config.host).to eq('test.example.com')
      expect(config.port).to eq(8007)
      expect(config.verify_ssl).to be false
      expect(config.timeout).to eq(60)

      ENV.delete('PROXMOX_HOST')
      ENV.delete('PROXMOX_PORT')
      ENV.delete('PROXMOX_VERIFY_SSL')
      ENV.delete('PROXMOX_TIMEOUT')
    end
  end

  describe '#merge' do
    it 'merges options with priority to provided values' do
      config = described_class.new
      config.host = 'default.example.com'
      config.port = 8006

      merged = config.merge(host: 'override.example.com', timeout: 60)

      expect(merged.host).to eq('override.example.com')
      expect(merged.port).to eq(8006)
      expect(merged.timeout).to eq(60)
    end

    it 'does not modify the original configuration' do
      config = described_class.new
      config.host = 'original.example.com'

      config.merge(host: 'modified.example.com')

      expect(config.host).to eq('original.example.com')
    end
  end

  describe 'attribute accessors' do
    it 'allows setting and getting attributes' do
      config = described_class.new

      config.host = 'proxmox.example.com'
      config.port = 8007
      config.verify_ssl = false
      config.timeout = 60

      expect(config.host).to eq('proxmox.example.com')
      expect(config.port).to eq(8007)
      expect(config.verify_ssl).to be false
      expect(config.timeout).to eq(60)
    end
  end
end
