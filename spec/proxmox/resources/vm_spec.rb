# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Proxmox::Resources::VM do
  let(:client) do
    Proxmox::Client.new(
      host: 'proxmox.example.com',
      token_name: 'user@pam!mytoken',
      token_value: 'secret-token-value'
    )
  end

  let(:node) { 'pve1' }
  let(:vmid) { 100 }
  let(:vm) { described_class.new(client, node: node, vmid: vmid) }

  describe '#disks' do
    it 'returns array of Disk objects' do
      stub_request(:get, "https://proxmox.example.com:8006/api2/json/nodes/#{node}/qemu/#{vmid}/config")
        .to_return(
          status: 200,
          body: {
            data: {
              'scsi0' => 'local-lvm:vm-100-disk-0,size=32G',
              'scsi1' => 'local-lvm:vm-100-disk-1,size=64G'
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      disks = vm.disks
      expect(disks).to be_an(Array)
      expect(disks.size).to eq(2)
      expect(disks.first).to be_a(Proxmox::Resources::Disk)
      expect(disks.first.disk_id).to eq('scsi0')
    end
  end

  describe '#resize_disk' do
    it 'resizes a disk' do
      stub_request(:put, "https://proxmox.example.com:8006/api2/json/nodes/#{node}/qemu/#{vmid}/resize")
        .with(body: hash_including(disk: 'scsi0', size: '+10G'))
        .to_return(
          status: 200,
          body: { data: 'UPID:pve1:00000000:00000000:00000000:qmresize:100:user@pam:' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = vm.resize_disk(disk_id: 'scsi0', size: '+10G')
      expect(result).to be_a(String)
    end
  end

  describe '#move_disk' do
    it 'moves a disk to different storage' do
      stub_request(:post, "https://proxmox.example.com:8006/api2/json/nodes/#{node}/qemu/#{vmid}/move_disk")
        .with(body: hash_including('disk' => 'scsi0', 'storage' => 'fast-ssd', 'delete' => '0'))
        .to_return(
          status: 200,
          body: { data: 'UPID:pve1:00000000:00000000:00000000:qmmove:100:user@pam:' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = vm.move_disk(disk_id: 'scsi0', storage: 'fast-ssd')
      expect(result).to be_a(String)
    end
  end

  describe '#add_disk' do
    it 'adds a new disk to the VM' do
      stub_request(:get, "https://proxmox.example.com:8006/api2/json/nodes/#{node}/qemu/#{vmid}/config")
        .to_return(
          status: 200,
          body: { data: {} }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:put, "https://proxmox.example.com:8006/api2/json/nodes/#{node}/qemu/#{vmid}/config")
        .with(body: hash_including('scsi0' => 'local-lvm:50'))
        .to_return(
          status: 200,
          body: { data: nil }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = vm.add_disk(storage: 'local-lvm', size: '50G')
      expect(result).to be_nil
    end
  end

  describe '#remove_disk' do
    it 'removes a disk from the VM' do
      stub_request(:put, "https://proxmox.example.com:8006/api2/json/nodes/#{node}/qemu/#{vmid}/config")
        .with(body: hash_including(delete: 'scsi1'))
        .to_return(
          status: 200,
          body: { data: nil }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = vm.remove_disk('scsi1')
      expect(result).to be_nil
    end
  end
end
