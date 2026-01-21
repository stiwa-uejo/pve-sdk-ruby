# Proxmox Ruby Library

A minimal, focused Ruby wrapper for the Proxmox VE API covering clusters, nodes, VMs (QEMU), containers (LXC), and storage management.

## Features

- **Cluster Management**: Status, resources, tasks, HA, backup jobs, firewall, replication
- **Node Management**: List nodes, get status, manage resources
- **VM Management**: Full lifecycle management, snapshots, cloning, disk operations
- **Container Management**: LXC container operations, volume management
- **Storage Management**: Storage status, content management, disk allocation
- **Disk Management**: Add, resize, move, and remove disks for VMs and containers
- **Minimal Dependencies**: Only uses standard library and JSON
- **Comprehensive Error Handling**: Custom exception hierarchy
- **Flexible Authentication**: Supports both password and API token authentication

## Installation

Add this line to your application's Gemfile:

TODO

Currently WIP, and not on rubygems.org


## Quick Start

### Authentication with API Token (Recommended)

```ruby
require 'proxmox'

client = Proxmox::Client.new(
  host: 'proxmox.example.com',
  token_name: 'user@pam!mytoken',
  token_value: 'secret-token-value',
  verify_ssl: true
)
```

### Authentication with Username/Password

```ruby
client = Proxmox::Client.new(
  host: 'proxmox.example.com',
  username: 'user@pam',
  password: 'secret',
  verify_ssl: true
)
```

### Environment Variables

You can also use environment variables:

```bash
export PROXMOX_HOST=proxmox.example.com
export PROXMOX_TOKEN_NAME=user@pam!mytoken
export PROXMOX_TOKEN_VALUE=secret-token-value
export PROXMOX_VERIFY_SSL=true
```

```ruby
client = Proxmox::Client.new
```

## Usage Examples

### Cluster Management

```ruby
# Get cluster status - returns typed objects
cluster = client.cluster
status = cluster.status
status.each do |item|
  puts "#{item.name}: #{item.type}"
end

# Get all cluster resources - returns typed objects (VM, Container, Node, Storage)
resources = cluster.resources
vms = resources.select { |r| r.is_a?(Proxmox::Resources::VM) }
puts "Total VMs: #{vms.count}"

# Or filter by type parameter
vms = cluster.resources(type: 'vm')  # Returns Array<VM>
vms.each { |vm| puts "#{vm.name} on #{vm.node}" }

# Get next available VMID
next_id = cluster.next_vmid
puts "Next VMID: #{next_id}"

# Create backup job
cluster.create_backup_job(
  schedule: '0 2 * * *',
  storage: 'backup-storage',
  vmid: '100,101,102',
  compress: 'zstd',
  mode: 'snapshot'
)

# Manage HA resources
cluster.create_ha_resource(
  sid: 'vm:100',
  state: 'started',
  group: 'production',
  max_restart: 3
)
```

### Node Management

```ruby
# List all nodes - returns Node objects
nodes = client.nodes.list
nodes.each do |node|
  puts "Node: #{node.node}, Status: #{node.status}"
end

# Get specific node
node = client.node('pve1')
status = node.status
puts "CPU: #{status['cpu']}, Memory: #{status['memory']['used']}/#{status['memory']['total']}"

# Get VMs on node - returns VM objects
vms = node.vms
puts "VMs on pve1: #{vms.count}"

# Work directly with VM objects
vms.each do |vm|
  puts "VM #{vm.vmid}: #{vm.name} (#{vm.status})"
  vm.start if vm.status == 'stopped'
end

# Check node status
if node.online?
  puts "Node is online"
end
```

### VM Management

```ruby
# Get all VMs - returns VM objects
vms = client.vms
vms.each do |vm|
  puts "#{vm.name} on #{vm.node}: #{vm.status}"
end

# Find VM by name
vm = client.vms.find { |v| v.name == 'web-server' }

# Or get VM directly
vm = client.vm('pve1', 100)

# Get status
status = vm.status
puts "VM Status: #{status['status']}"
puts "Uptime: #{status['uptime']} seconds"

# Start/Stop operations
vm.start
vm.stop
vm.shutdown(timeout: 60)
vm.reboot
vm.reset

# Suspend/Resume
vm.suspend
vm.resume

# Update configuration (supports keywords or hash)
vm.update(
  cores: 4,
  memory: 4096,
  description: 'Updated VM'
)

# Or using a hash
spec = { cores: 2, sockets: 1 }
vm.update(spec)

# Snapshot management
vm.create_snapshot(
  name: 'before-update',
  description: 'Snapshot before system update'
)

snapshots = vm.snapshots
snapshots.each do |snap|
  puts "Snapshot: #{snap['name']}"
end

vm.delete_snapshot('before-update')

# Clone VM
vm.clone(
  newid: 101,
  name: 'cloned-vm',
  full: true
)

# Delete VM
vm.delete

# Batch operations with method chaining
client.vms
  .select { |vm| vm.status == 'running' }
  .each(&:stop)
```

### Disk Management

```ruby
# VM Disk Operations
vm = client.vm('pve1', 100)

# List all disks - returns Disk objects
disks = vm.disks
disks.each do |disk|
  puts "#{disk.disk_id}: #{disk.storage}:#{disk.size}"
end

# Get specific disk
disk = vm.disk('scsi0')
puts "Storage: #{disk.storage}, Size: #{disk.size}"

# Add a new disk
vm.add_disk(
  disk_type: 'scsi',      # scsi, virtio, ide, sata
  storage: 'local-lvm',
  size: 10,               # Size in GB
  ssd: true,
  discard: true,
  cache: 'writeback'
)

# Resize a disk (use +/- for relative sizing)
vm.resize_disk(disk_id: 'scsi0', size: '+5G')   # Add 5GB
vm.resize_disk(disk_id: 'scsi1', size: '20G')   # Set to 20GB

# Move disk to different storage
vm.move_disk(
  disk_id: 'scsi0',
  storage: 'fast-ssd',
  delete: true  # Delete source after move
)

# Remove a disk
vm.remove_disk(disk_id: 'scsi1')

# Container Volume Operations
container = client.container('pve1', 101)

# List all volumes
volumes = container.volumes
volumes.each do |vol|
  puts "#{vol.disk_id}: #{vol.storage}"
end

# Resize rootfs
container.resize_rootfs(size: '+2G')

# Add a mountpoint
container.add_mountpoint(
  mp_id: 'mp0',
  storage: 'local-lvm',
  size: 5,                # Size in GB
  path: '/mnt/data',
  backup: true,
  readonly: false
)

# Resize a mountpoint
container.resize_mountpoint(mp_id: 'mp0', size: '+1G')

# Move volume to different storage
container.move_volume(
  volume: 'mp0',
  storage: 'backup-storage',
  delete: true
)

# Remove a mountpoint
container.remove_mountpoint('mp0')

# Storage Operations
storage = client.storage('local-lvm')

# Allocate a new disk
storage.allocate_disk(
  vmid: 100,
  filename: 'vm-100-disk-1',
  size: '10G'
)

# Get volume information
vol_info = storage.volume_info('vm-100-disk-0')
puts "Format: #{vol_info['format']}, Size: #{vol_info['size']}"

# List VM volumes on storage
volumes = storage.vm_volumes(vmid: 100)
volumes.each do |vol|
  puts "#{vol['volid']}: #{vol['size']}"
end
```

### Container Management

```ruby
# Get container
container = client.container('pve1', 101)

# Status and operations
status = container.status
puts "Container Status: #{status['status']}"

container.start
container.stop
container.shutdown(timeout: 60)
container.reboot

# Update configuration
container.update(
  memory: 1024,
  swap: 512,
  hostname: 'new-hostname'
)

# Snapshot management
container.create_snapshot(
  name: 'backup',
  description: 'Before changes'
)

container.snapshots
container.delete_snapshot('backup')
```

### Storage Management

```ruby
# Get storage
storage = client.storage('pve1', 'local-lvm')

# Get status
status = storage.status
puts "Total: #{status['total']}, Used: #{status['used']}, Available: #{status['avail']}"

# List content
images = storage.content(type: 'images')
images.each do |image|
  puts "Image: #{image['volid']}, Size: #{image['size']}"
end

# Delete volume
storage.delete_volume('local-lvm:vm-100-disk-0')
```

## Configuration

### Global Configuration

```ruby
Proxmox.configure do |config|
  config.host = 'proxmox.example.com'
  config.port = 8006
  config.verify_ssl = true
  config.timeout = 30
end

client = Proxmox::Client.new(
  token_name: 'user@pam!mytoken',
  token_value: 'secret'
)
```

### Per-Client Configuration

```ruby
client = Proxmox::Client.new(
  host: 'proxmox.example.com',
  port: 8006,
  token_name: 'user@pam!mytoken',
  token_value: 'secret',
  verify_ssl: true,
  timeout: 30
)
```

## Error Handling

The library provides a comprehensive error hierarchy:

```ruby
begin
  vm = client.vm('pve1', 999)
  vm.start
rescue Proxmox::NotFoundError => e
  puts "VM not found: #{e.message}"
rescue Proxmox::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue Proxmox::ValidationError => e
  puts "Invalid parameters: #{e.message}"
rescue Proxmox::APIError => e
  puts "API error: #{e.message}"
rescue Proxmox::TimeoutError => e
  puts "Request timeout: #{e.message}"
rescue Proxmox::ConnectionError => e
  puts "Connection failed: #{e.message}"
rescue Proxmox::Error => e
  puts "Proxmox error: #{e.message}"
end
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rspec` to run the tests.

### Running Tests

```bash
bundle exec rspec
```

### Code Style

```bash
bundle exec rubocop
```

### Documentation

Generate documentation with YARD:

```bash
bundle exec yard doc
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Roadmap

- [x] Disk management for VMs and containers
- [ ] Add support for more cluster endpoints (SDN, ACME, etc.)
- [ ] Implement VM creation from templates
- [ ] Add container creation support
- [ ] Implement task monitoring and waiting
- [ ] Add support for Proxmox Backup Server API
- [ ] Improve file upload handling for ISOs and templates
- [ ] Add pagination support for large result sets
- [ ] Implement retry logic with exponential backoff

## Credits

This library was designed and implemented based on the Proxmox VE API documentation.
