#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/proxmox'

# Configure Proxmox connection
Proxmox.configure do |config|
  config.endpoint = 'https://10.172.101.224:8006'
  config.username = 'root@pam'
  config.password = 'Stiwa2020!'
  config.verify_ssl = false
end

client = Proxmox::Client.new

puts "=== Proxmox Disk Operations Demo ===\n\n"

# === VM Disk Operations ===
puts '1. VM Disk Operations'
puts '-' * 50

vm = client.vm(node: 'devsmiqpvetest', vmid: 100)
puts "VM: #{vm.name} (#{vm.vmid})"

# List current disks
puts "\nCurrent disks:"
vm.disks.each do |disk|
  puts "  - #{disk.disk_id}: #{disk.storage}:#{disk.size}"
end

# Add a new disk
puts "\nAdding a 2GB SCSI disk..."
begin
  vm.add_disk(
    disk_type: 'scsi',
    storage: 'local-lvm',
    size: 2,
    ssd: true,
    discard: true
  )
  puts '✓ Disk added successfully'
rescue StandardError => e
  puts "✗ Failed: #{e.message}"
end

# Resize a disk
puts "\nResizing scsi1 by +512M..."
begin
  result = vm.resize_disk(disk_id: 'scsi1', size: '+512M')
  puts '✓ Disk resized successfully'
  puts "  Task: #{result}"
rescue StandardError => e
  puts "✗ Failed: #{e.message}"
end

# Get specific disk info
puts "\nGetting scsi0 disk details..."
disk = vm.disk('scsi0')
puts "  Storage: #{disk.storage}"
puts "  Size: #{disk.size}"
puts "  Volume ID: #{disk.volid}"

# Remove a disk
puts "\nRemoving scsi2..."
begin
  vm.remove_disk(disk_id: 'scsi2')
  puts '✓ Disk removed successfully'
rescue StandardError => e
  puts "✗ Failed: #{e.message}"
end

# === Container Volume Operations ===
puts "\n\n2. Container Volume Operations"
puts '-' * 50

container = client.container(node: 'devsmiqpvetest', vmid: 115)
puts "Container: #{container.hostname} (#{container.vmid})"

# List current volumes
puts "\nCurrent volumes:"
container.volumes.each do |vol|
  puts "  - #{vol.disk_id}: #{vol.storage}"
end

# Resize rootfs
puts "\nResizing rootfs by +256M..."
begin
  container.resize_rootfs(size: '+256M')
  puts '✓ Rootfs resized successfully'
rescue StandardError => e
  puts "✗ Failed: #{e.message}"
end

# Add a mountpoint
puts "\nAdding a 1GB mountpoint at /mnt/data..."
begin
  container.add_mountpoint(
    mp_id: 'mp1',
    storage: 'local-lvm',
    size: 1,
    path: '/mnt/data',
    backup: true
  )
  puts '✓ Mountpoint added successfully'
rescue StandardError => e
  puts "✗ Failed: #{e.message}"
end

# Resize a mountpoint
puts "\nResizing mp0 by +128M..."
begin
  container.resize_mountpoint(mp_id: 'mp0', size: '+128M')
  puts '✓ Mountpoint resized successfully'
rescue StandardError => e
  puts "✗ Failed: #{e.message}"
end

# Remove a mountpoint
puts "\nRemoving mp1..."
begin
  container.remove_mountpoint('mp1')
  puts '✓ Mountpoint removed successfully'
rescue StandardError => e
  puts "✗ Failed: #{e.message}"
end

# === Storage Operations ===
puts "\n\n3. Storage Operations"
puts '-' * 50

storage = client.storage('local-lvm')
puts "Storage: #{storage.storage}"

# List VM volumes on this storage
puts "\nVM volumes on #{storage.storage}:"
begin
  volumes = storage.vm_volumes(vmid: 100)
  volumes.each do |vol|
    puts "  - #{vol['volid']}: #{vol['size']}"
  end
rescue StandardError => e
  puts "✗ Failed: #{e.message}"
end

# Get volume info
puts "\nGetting volume info for vm-100-disk-0..."
begin
  vol_info = storage.volume_info('vm-100-disk-0')
  puts "  Format: #{vol_info['format']}"
  puts "  Size: #{vol_info['size']}"
  puts "  Used: #{vol_info['used']}"
rescue StandardError => e
  puts "✗ Failed: #{e.message}"
end

puts "\n=== Demo Completed ===\n"
