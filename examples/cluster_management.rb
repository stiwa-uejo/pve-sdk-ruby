#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'proxmox'

# This example demonstrates cluster management operations

client = Proxmox::Client.new(
  host: ENV['PROXMOX_HOST'] || 'proxmox.example.com',
  token_name: ENV['PROXMOX_TOKEN_NAME'] || 'user@pam!mytoken',
  token_value: ENV['PROXMOX_TOKEN_VALUE'] || 'secret-token-value',
  verify_ssl: true
)

puts '=== Cluster Management Example ==='
puts

begin
  cluster = client.cluster

  # Get cluster status
  puts 'Cluster Status:'
  status = cluster.status
  status.each do |item|
    next unless item.type == 'cluster'

    puts "  Cluster: #{item.name}"
    puts "  Nodes: #{item.nodes}"
    puts "  Quorate: #{item.quorate}"
  end
  puts

  # Get all cluster resources
  puts 'Cluster Resources Summary:'
  resources = cluster.resources

  resource_types = resources.group_by { |r| r.class.name.split('::').last }
  resource_types.each do |type, items|
    puts "  - #{type}: #{items.count}"
  end
  puts

  # Get VMs across all nodes
  puts 'Virtual Machines:'
  vms = resources.select { |r| r.is_a?(Proxmox::Resources::VM) }
  vms.first(10).each do |vm|
    status_icon = vm.status == 'running' ? '✓' : '✗'
    puts "  #{status_icon} VMID #{vm.vmid}: #{vm.name} on #{vm.node} (#{vm.status})"
  end
  puts "  ... and #{vms.count - 10} more" if vms.count > 10
  puts

  # Get containers across all nodes
  puts 'Containers:'
  containers = resources.select { |r| r.is_a?(Proxmox::Resources::Container) }
  if containers.any?
    containers.first(10).each do |ct|
      status_icon = ct.status == 'running' ? '✓' : '✗'
      puts "  #{status_icon} CTID #{ct.vmid}: #{ct.name} on #{ct.node} (#{ct.status})"
    end
    puts "  ... and #{containers.count - 10} more" if containers.count > 10
  else
    puts '  No containers found'
  end
  puts

  # Get storage resources
  puts 'Storage:'
  storage_items = resources.select { |r| r.is_a?(Proxmox::Resources::Storage) }
  storage_items.each do |st|
    used_pct = (st.disk.to_f / st.maxdisk * 100).round(2) if st.maxdisk&.positive?
    disk_gb = st.disk / 1024 / 1024 / 1024
    maxdisk_gb = st.maxdisk / 1024 / 1024 / 1024
    puts "  - #{st.storage} on #{st.node}: #{disk_gb} GB / #{maxdisk_gb} GB (#{used_pct}%)"
  end
  puts

  # Get next available VMID
  next_vmid = cluster.next_vmid
  puts "Next available VMID: #{next_vmid}"
  puts

  # List cluster tasks
  puts 'Recent Cluster Tasks:'
  tasks = cluster.tasks(limit: 10)
  tasks.each do |task|
    status_icon = if task['status'] == 'OK'
                    '✓'
                  else
                    (task['status'] == 'running' ? '⟳' : '✗')
                  end
    puts "  #{status_icon} #{task['type']}: #{task['id']} on #{task['node']} (#{task['status']})"
  end
  puts

  # List HA resources
  puts 'HA Resources:'
  ha_resources = cluster.ha_resources
  if ha_resources.any?
    ha_resources.each do |ha|
      puts "  - #{ha['sid']}: state=#{ha['state']}, group=#{ha['group']}"
    end
  else
    puts '  No HA resources configured'
  end
  puts

  # List backup jobs
  puts 'Backup Jobs:'
  backup_jobs = cluster.backup_jobs
  if backup_jobs.any?
    backup_jobs.each do |job|
      puts "  - #{job['id']}: schedule=#{job['schedule']}, storage=#{job['storage']}"
    end
  else
    puts '  No backup jobs configured'
  end
  puts

  # List replication jobs
  puts 'Replication Jobs:'
  replication_jobs = cluster.replication_jobs
  if replication_jobs.any?
    replication_jobs.each do |job|
      puts "  - #{job['id']}: guest=#{job['guest']}, target=#{job['target']}"
    end
  else
    puts '  No replication jobs configured'
  end
  puts

  # Example: Create HA resource (UNCOMMENT TO USE)
  # puts "Creating HA resource..."
  # cluster.create_ha_resource(
  #   sid: 'vm:100',
  #   state: 'started',
  #   group: 'production',
  #   max_restart: 3,
  #   max_relocate: 3
  # )
  # puts "HA resource created"
  # puts

  # Example: Create backup job (UNCOMMENT TO USE)
  # puts "Creating backup job..."
  # cluster.create_backup_job(
  #   schedule: '0 2 * * *',
  #   storage: 'backup-storage',
  #   vmid: '100,101,102',
  #   compress: 'zstd',
  #   mode: 'snapshot',
  #   enabled: true
  # )
  # puts "Backup job created"
  # puts

  puts '=== Example completed successfully ==='
rescue Proxmox::AuthenticationError => e
  puts "ERROR: Authentication failed - #{e.message}"
  puts 'Please check your credentials'
rescue Proxmox::Error => e
  puts "ERROR: #{e.class} - #{e.message}"
end
