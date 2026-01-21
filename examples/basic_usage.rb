#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'proxmox'

# This example demonstrates basic usage of the Proxmox library
# Make sure to set your environment variables or update the credentials below

# Option 1: Use environment variables
# export PROXMOX_HOST=proxmox.example.com
# export PROXMOX_TOKEN_NAME=user@pam!mytoken
# export PROXMOX_TOKEN_VALUE=secret-token-value
# OR
# export PROXMOX_USERNAME=root@pam
# export PROXMOX_PASSWORD=secret

puts '=== Proxmox Library - Basic Usage Example ==='
puts

host = ENV['PROXMOX_HOST'] || 'proxmox.example.com'
verify_ssl = ENV['PROXMOX_VERIFY_SSL'] != 'false'

client = if ENV['PROXMOX_TOKEN_NAME'] && ENV['PROXMOX_TOKEN_VALUE']
           puts "Using Token Authentication (Token: #{ENV['PROXMOX_TOKEN_NAME']})"
           Proxmox::Client.new(
             host: host,
             token_name: ENV['PROXMOX_TOKEN_NAME'],
             token_value: ENV['PROXMOX_TOKEN_VALUE'],
             verify_ssl: verify_ssl
           )
         elsif ENV['PROXMOX_USERNAME'] && ENV['PROXMOX_PASSWORD']
           puts "Using Password Authentication (User: #{ENV['PROXMOX_USERNAME']})"
           Proxmox::Client.new(
             host: host,
             username: ENV['PROXMOX_USERNAME'],
             password: ENV['PROXMOX_PASSWORD'],
             verify_ssl: verify_ssl
           )
         else
           puts 'Using Default Demo Credentials (Token)'
           Proxmox::Client.new(
             host: host,
             token_name: 'user@pam!mytoken',
             token_value: 'secret-token-value',
             verify_ssl: verify_ssl
           )
         end

puts "Connecting to #{host}..."
puts

# Get cluster status
begin
  puts 'Cluster Status:'
  cluster = client.cluster
  status = cluster.status
  status.each do |item|
    puts "  - #{item.name}: #{item.type} (#{item.online ? 'online' : 'offline'})"
  end
  puts

  # List all nodes
  puts 'Nodes:'
  nodes = client.nodes.list
  nodes.each do |node|
    puts "  - #{node.node}: #{node.status} (CPU: #{node.cpu}, Memory: #{node.mem})"
  end
  puts

  # Get cluster resources
  puts 'Cluster Resources:'
  resources = cluster.resources
  vms = resources.select { |r| r.is_a?(Proxmox::Resources::VM) }
  containers = resources.select { |r| r.is_a?(Proxmox::Resources::Container) }
  puts "  - VMs: #{vms.count}"
  puts "  - Containers: #{containers.count}"
  puts

  # List VMs
  if vms.any?
    puts 'Virtual Machines:'
    vms.first(5).each do |vm|
      puts "  - VMID #{vm.vmid}: #{vm.name} on #{vm.node} (#{vm.status})"
    end
    puts
  end

  # Get next available VMID
  next_vmid = cluster.next_vmid
  puts "Next available VMID: #{next_vmid}"
  puts

  # Example: Get specific VM details (update VMID and node as needed)
  if vms.any?
    vm = vms.first

    puts "VM Details for VMID #{vm.vmid}:"
    vm_status = vm.status
    puts "  - Name: #{vm_status['name']}"
    puts "  - Status: #{vm_status['status']}"
    puts "  - CPU: #{vm_status['cpus']} cores"
    puts "  - Memory: #{vm_status['maxmem'] / 1024 / 1024} MB"
    puts "  - Uptime: #{vm_status['uptime']} seconds" if vm_status['uptime']
    puts
  end

  puts '=== Example completed successfully ==='
rescue Proxmox::AuthenticationError => e
  puts "Authentication Failed: #{e.message}"
  puts 'Please check your credentials.'
rescue Proxmox::ConnectionError => e
  puts "Connection Failed: #{e.message}"
  puts 'Please check the host address and network connection.'
rescue StandardError => e
  puts "An error occurred: #{e.class} - #{e.message}"
  puts e.backtrace.first(5)
end
