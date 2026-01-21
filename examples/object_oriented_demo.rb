#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'proxmox'

# This example demonstrates the new object-oriented API in v2.0

client = Proxmox::Client.new(
  host: ENV['PROXMOX_HOST'] || 'proxmox.example.com',
  token_name: ENV['PROXMOX_TOKEN_NAME'] || 'user@pam!mytoken',
  token_value: ENV['PROXMOX_TOKEN_VALUE'] || 'secret-token-value',
  verify_ssl: true
)

puts '=== Object-Oriented API Demo ==='
puts

# Example 1: Working with Node objects
puts '1. Node Objects:'
nodes = client.nodes.list # Returns Array<Node>
nodes.each do |node|
  puts "  - #{node.node}: #{node.status} (CPU: #{node.cpu})"
end
puts

# Example 2: Working with VM objects
puts '2. VM Objects:'
vms = client.vms # Returns Array<VM>
vms.first(5).each do |vm|
  puts "  - VM #{vm.vmid}: #{vm.name} on #{vm.node} (#{vm.status})"
end
puts

# Example 3: Method chaining
puts '3. Method Chaining - Find running VMs:'
running_vms = client.vms.select { |vm| vm.status == 'running' }
puts "  Found #{running_vms.count} running VMs"
running_vms.first(3).each do |vm|
  puts "    - #{vm.name}"
end
puts

# Example 4: Type-safe filtering
puts '4. Type-Safe Resource Filtering:'
resources = client.cluster.resources
vms = resources.select { |r| r.is_a?(Proxmox::Resources::VM) }
containers = resources.select { |r| r.is_a?(Proxmox::Resources::Container) }
nodes = resources.select { |r| r.is_a?(Proxmox::Resources::Node) }
storage = resources.select { |r| r.is_a?(Proxmox::Resources::Storage) }

puts "  - VMs: #{vms.count}"
puts "  - Containers: #{containers.count}"
puts "  - Nodes: #{nodes.count}"
puts "  - Storage: #{storage.count}"
puts

# Example 5: Direct object operations
puts '5. Direct Object Operations:'
if vms.any?
  vm = vms.first
  puts "  Working with VM: #{vm.name}"
  puts "    - VMID: #{vm.vmid}"
  puts "    - Node: #{vm.node}"
  puts "    - Status: #{vm.status}"

  # Can call methods directly on the object
  # vm.start  # Uncomment to actually start the VM
  puts '    - Can call vm.start, vm.stop, etc. directly!'
end
puts

# Example 6: Hash compatibility
puts '6. Hash Compatibility:'
if vms.any?
  vm = vms.first
  puts "  Object access (preferred): vm.name = #{vm.name}"
  puts "  Hash access (still works): vm['name'] = #{vm['name']}"
  puts "  Convert to hash: vm.to_h.keys = #{vm.to_h.keys.first(5).join(', ')}"
end
puts

# Example 7: Finding specific resources
puts '7. Finding Specific Resources:'
web_vm = client.vms.find { |v| v.name&.include?('web') }
if web_vm
  puts "  Found web server: #{web_vm.name} (VMID: #{web_vm.vmid})"
else
  puts '  No web server found'
end
puts

# Example 8: Working with node-specific resources
puts '8. Node-Specific Resources:'
if nodes.any?
  node = nodes.first
  puts "  Node: #{node.node}"

  node_vms = node.vms # Returns Array<VM>
  puts "    - VMs: #{node_vms.count}"

  node_containers = node.containers # Returns Array<Container>
  puts "    - Containers: #{node_containers.count}"

  node_storage = node.storage # Returns Array<Storage>
  puts "    - Storage: #{node_storage.count}"
end
puts

puts '=== Demo completed successfully ==='
puts
puts 'Key Takeaways:'
puts '  ✓ All collections return objects, not hashes'
puts '  ✓ Access attributes with vm.name instead of vm[\'name\']'
puts '  ✓ Chain methods naturally: client.vms.select { }.each { }'
puts '  ✓ Type-safe filtering with is_a?(Proxmox::Resources::VM)'
puts '  ✓ Hash compatibility maintained for gradual migration'
