#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'proxmox'

# This example demonstrates VM management operations
# WARNING: This example includes destructive operations (commented out by default)

client = Proxmox::Client.new(
  host: ENV['PROXMOX_HOST'] || 'proxmox.example.com',
  token_name: ENV['PROXMOX_TOKEN_NAME'] || 'user@pam!mytoken',
  token_value: ENV['PROXMOX_TOKEN_VALUE'] || 'secret-token-value',
  verify_ssl: true
)

puts '=== VM Management Example ==='
puts

# Configuration - UPDATE THESE VALUES
NODE_NAME = 'pve1'  # Your Proxmox node name
VMID = 100          # Your VM ID

begin
  # Get VM instance
  vm = client.vm(NODE_NAME, VMID)

  # Get current status
  puts 'Getting VM status...'
  status = vm.status
  puts "VM #{VMID} Status:"
  puts "  - Name: #{status['name']}"
  puts "  - Status: #{status['status']}"
  puts "  - CPU: #{status['cpus']} cores"
  puts "  - Memory: #{status['maxmem'] / 1024 / 1024} MB"
  puts "  - Disk: #{status['maxdisk'] / 1024 / 1024 / 1024} GB" if status['maxdisk']
  puts

  # Get current configuration
  puts 'Getting VM configuration...'
  config = vm.config
  puts 'VM Configuration:'
  puts "  - Boot order: #{config['boot']}" if config['boot']
  puts "  - OS Type: #{config['ostype']}" if config['ostype']
  puts "  - BIOS: #{config['bios']}" if config['bios']
  puts

  # List snapshots
  puts 'Listing snapshots...'
  snapshots = vm.snapshots
  if snapshots.any?
    puts 'Snapshots:'
    snapshots.each do |snap|
      puts "  - #{snap['name']}: #{snap['description']}"
    end
  else
    puts 'No snapshots found'
  end
  puts

  # Example: Create a snapshot (UNCOMMENT TO USE)
  # puts "Creating snapshot..."
  # vm.create_snapshot(
  #   name: 'test-snapshot',
  #   description: 'Test snapshot created by example script'
  # )
  # puts "Snapshot created successfully"
  # puts

  # Example: Update VM configuration (UNCOMMENT TO USE)
  # puts "Updating VM configuration..."
  # vm.update(
  #   description: 'Updated by Proxmox Ruby library example',
  #   cores: 2,       # Set number of CPU cores
  #   memory: 2048    # Set memory in MB
  # )
  # puts "Configuration updated successfully"
  # puts

  # Example: VM lifecycle operations (UNCOMMENT TO USE - BE CAREFUL!)
  #
  # # Start VM
  # puts "Starting VM..."
  # vm.start
  # puts "VM started"
  # sleep 5
  #
  # # Suspend VM
  # puts "Suspending VM..."
  # vm.suspend
  # puts "VM suspended"
  # sleep 2
  #
  # # Resume VM
  # puts "Resuming VM..."
  # vm.resume
  # puts "VM resumed"
  # sleep 2
  #
  # # Shutdown VM gracefully
  # puts "Shutting down VM..."
  # vm.shutdown(timeout: 60)
  # puts "VM shutdown initiated"

  # Example: Clone VM (UNCOMMENT TO USE)
  # next_vmid = client.cluster.next_vmid
  # puts "Cloning VM to VMID #{next_vmid}..."
  # vm.clone(
  #   newid: next_vmid,
  #   name: "clone-of-#{VMID}",
  #   description: 'Cloned by example script',
  #   full: true
  # )
  # puts "VM cloned successfully"
  # puts

  puts '=== Example completed successfully ==='
rescue Proxmox::NotFoundError => e
  puts "ERROR: VM not found - #{e.message}"
  puts 'Please update NODE_NAME and VMID in the script'
rescue Proxmox::AuthenticationError => e
  puts "ERROR: Authentication failed - #{e.message}"
  puts 'Please check your credentials'
rescue Proxmox::Error => e
  puts "ERROR: #{e.class} - #{e.message}"
end
