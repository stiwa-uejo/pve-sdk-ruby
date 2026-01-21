# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Proxmox::Resources::Disk do
  let(:client) do
    Proxmox::Client.new(
      host: 'proxmox.example.com',
      token_name: 'user@pam!mytoken',
      token_value: 'secret-token-value'
    )
  end

  let(:node) { 'pve1' }
  let(:vmid) { 100 }

  describe '#initialize' do
    it 'creates a VM disk object' do
      disk = described_class.new(
        client,
        node: node,
        vmid: vmid,
        disk_id: 'scsi0',
        storage: 'local-lvm',
        size: '32G'
      )

      expect(disk.node.name).to eq(node)
      expect(disk.vmid).to eq(vmid)
      expect(disk.disk_id).to eq('scsi0')
      expect(disk.storage).to eq('local-lvm')
    end

    it 'creates a container volume object' do
      disk = described_class.new(
        client,
        node: node,
        vmid: vmid,
        disk_id: 'rootfs',
        storage: 'local-lvm'
      )

      expect(disk.disk_id).to eq('rootfs')
      expect(disk.type).to eq(:container_rootfs)
    end
  end

  describe '#vm_disk?' do
    it 'returns true for VM disks' do
      disk = described_class.new(client, node: node, vmid: vmid, disk_id: 'scsi0')
      expect(disk.vm_disk?).to be true
    end

    it 'returns false for container volumes' do
      disk = described_class.new(client, node: node, vmid: vmid, disk_id: 'rootfs')
      expect(disk.vm_disk?).to be false
    end
  end

  describe '#container_volume?' do
    it 'returns true for container volumes' do
      disk = described_class.new(client, node: node, vmid: vmid, disk_id: 'rootfs')
      expect(disk.container_volume?).to be true
    end

    it 'returns false for VM disks' do
      disk = described_class.new(client, node: node, vmid: vmid, disk_id: 'scsi0')
      expect(disk.container_volume?).to be false
    end
  end

  describe '#resize' do
    let(:disk) { described_class.new(client, node: node, vmid: vmid, disk_id: 'scsi0') }

    it 'resizes a VM disk' do
      stub_request(:put, "https://proxmox.example.com:8006/api2/json/nodes/#{node}/qemu/#{vmid}/resize")
        .with(body: hash_including(disk: 'scsi0', size: '+10G'))
        .to_return(
          status: 200,
          body: { data: 'UPID:pve1:00000000:00000000:00000000:qmresize:100:user@pam:' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = disk.resize(size: '+10G')
      expect(result).to be_a(String)
    end
  end

  describe '#move' do
    let(:disk) { described_class.new(client, node: node, vmid: vmid, disk_id: 'scsi0') }

    it 'moves a VM disk to different storage' do
      stub_request(:post, "https://proxmox.example.com:8006/api2/json/nodes/#{node}/qemu/#{vmid}/move_disk")
        .with(body: hash_including('disk' => 'scsi0', 'storage' => 'fast-ssd', 'delete' => '0'))
        .to_return(
          status: 200,
          body: { data: 'UPID:pve1:00000000:00000000:00000000:qmmove:100:user@pam:' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = disk.move(storage: 'fast-ssd')
      expect(result).to be_a(String)
    end
  end
end
