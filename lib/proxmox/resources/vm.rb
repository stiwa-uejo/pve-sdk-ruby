# frozen_string_literal: true

module Proxmox
  module Resources
    # rubocop:disable Metrics/ClassLength
    class VM < Base
      DISK_LIMITS = {
        'ide' => 4,
        'scsi' => 31,
        'virtio' => 16,
        'sata' => 6
      }.freeze

      DiskConfig = Struct.new(:id, :volid, :storage, :disk_size, keyword_init: true)

      attr_reader :vmid

      def initialize(client, node:, vmid:, **attrs)
        @node_name = node
        @vmid = vmid
        super(client, **attrs)
      end

      def node
        Resources::Node.new(@client, node: @node_name)
      end

      def load_details
        stat = status
        cfg = config(reload: true)

        @attributes.merge!(stat)
        @attributes.merge!(cfg)

        populate_attributes
        self
      end

      def name
        return @name if defined?(@name)

        status['name']
      end

      def template
        return @template if defined?(@template)

        config['template'].to_i
      end

      def status
        response = http_get("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/status/current")
        extract_data(response)
      end

      def config(reload: false)
        return @config_cache if @config_cache && !reload

        response = http_get("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/config")
        @config_cache = extract_data(response)
      end

      def method_missing(method_name, *args, &block)
        key = method_name.to_s
        cfg = config

        if cfg.key?(key)
          @attributes[key] = cfg[key]
          populate_attributes
          return cfg[key]
        end

        super
      end

      def respond_to_missing?(method_name, include_private = false)
        return true if @config_cache&.key?(method_name.to_s)

        super
      end

      def start
        response = http_post("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/status/start")
        extract_data(response)
      end

      def stop(force: false)
        params = force ? { skiplock: 1 } : {}
        response = http_post("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/status/stop", params: params)
        extract_data(response)
      end

      def shutdown(timeout: 60)
        response = http_post("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/status/shutdown",
                        params: { timeout: timeout })
        extract_data(response)
      end

      def reboot
        response = http_post("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/status/reboot")
        extract_data(response)
      end

      def reset
        response = http_post("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/status/reset")
        extract_data(response)
      end

      def suspend
        response = http_post("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/status/suspend")
        extract_data(response)
      end

      def resume
        response = http_post("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/status/resume")
        extract_data(response)
      end

      def update(params = {}, **kwargs)
        merged_params = params.merge(kwargs)
        response = http_put("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/config", params: merged_params)
        extract_data(response)
      end

      def delete
        response = http_delete("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}")
        extract_data(response)
      end

      def snapshots
        response = http_get("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/snapshot")
        extract_data(response)
      end

      def create_snapshot(name:, description: nil)
        params = { snapname: name }
        params[:description] = description if description
        response = http_post("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/snapshot", params: params)
        extract_data(response)
      end

      def delete_snapshot(name)
        response = http_delete("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/snapshot/#{name}")
        extract_data(response)
      end

      def rollback_snapshot(name)
        response = http_post("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/snapshot/#{name}/rollback")
        extract_data(response)
      end

      def clone(newid:, **params)
        params[:newid] = newid
        response = http_post("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/clone", params: params)
        extract_data(response)
      end

      def start_console(generate_password: false)
        params = {}
        params[:'generate-password'] = 1 if generate_password

        response = http_post(
          "/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/vncproxy",
          params: params
        )
        extract_data(response)
      end
      alias vncproxy start_console

      def agent_network_interfaces
        response = http_get("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/agent/network-get-interfaces")
        extract_data(response)
      rescue Proxmox::APIError
        nil
      end

      def agent_hostname
        response = http_get("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/agent/get-host-name")
        data = extract_data(response)
        data&.dig('result', 'host-name')
      rescue Proxmox::APIError
        nil
      end

      def agent_osinfo
        response = http_get("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/agent/get-osinfo")
        data = extract_data(response)
        data&.dig('result')
      rescue Proxmox::APIError
        nil
      end

      def guest_agent_ip_addresses(ip_type: 'ipv4')
        interfaces = agent_network_interfaces
        return [] unless interfaces&.dig('result')

        interfaces['result'].flat_map do |iface|
          next [] unless iface['ip-addresses']

          filtered = iface['ip-addresses'].select do |ip|
            !ip_type || ip['ip-address-type'] == ip_type
          end

          filtered.map do |ip_info|
            {
              interface: iface['name'],
              ip: ip_info['ip-address'],
              mac: iface['hardware-address'],
              type: ip_info['ip-address-type']
            }
          end
        end
      rescue Proxmox::APIError
        []
      end

      alias guest_agent_hostname agent_hostname
      alias guest_agent_osinfo agent_osinfo

      def agent_enabled?
        config['agent'].to_s == '1'
      end

      def config_disks
        disks = []
        iterate_disks do |disk_key, disk_string|
          disk_config = Resources::Disk.parse_config(disk_string)
          disks << DiskConfig.new(
            id: disk_key,
            volid: disk_config[:volid],
            storage: disk_config[:storage],
            disk_size: disk_config[:size]
          )
        end
        disks
      end

      def disks
        disk_list = []
        iterate_disks do |disk_key, disk_string|
          disk_attrs = Resources::Disk.parse_config(disk_string)
          disk_list << Resources::Disk.new(
            @client,
            node: @node_name,
            vmid: @vmid,
            disk_id: disk_key,
            **disk_attrs
          )
        end
        disk_list
      end

      def disk(disk_id)
        disks.find { |d| d.disk_id == disk_id }
      end

      def resize_disk(disk_id:, size:)
        response = http_put(
          "/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/resize",
          params: { disk: disk_id, size: size }
        )
        extract_data(response)
      end

      def move_disk(disk_id:, storage:, delete: false, format: nil)
        params = {
          disk: disk_id,
          storage: storage,
          delete: delete ? 1 : 0
        }
        params[:format] = format if format

        response = http_post("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/move_disk", params: params)
        extract_data(response)
      end

      def add_disk(storage:, size:, disk_type: 'scsi', disk_id: nil,
                   ssd: false, discard: false, cache: nil, format: nil)
        disk_id ||= find_next_disk_slot(disk_type)

        options = {}
        options[:ssd] = ssd
        options[:discard] = discard
        options[:cache] = cache if cache
        options[:format] = format if format

        disk_config = Resources::Disk.build_config(storage, size, options)

        response = http_put(
          "/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/config",
          params: { disk_id.to_sym => disk_config }
        )
        extract_data(response)
      end

      def remove_disk(disk_id)
        response = http_put(
          "/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/config",
          params: { delete: disk_id }
        )
        extract_data(response)
      end

      private

      def iterate_disks
        config_data = config
        %w[ide scsi virtio sata].each do |interface|
          max_disks = DISK_LIMITS[interface]
          max_disks.times do |i|
            disk_key = "#{interface}#{i}"
            next unless config_data[disk_key]

            yield disk_key, config_data[disk_key]
          end
        end
      end

      def find_next_disk_slot(interface)
        config_data = config
        max_disks = DISK_LIMITS.fetch(interface, 16)

        max_disks.times do |i|
          disk_id = "#{interface}#{i}"
          return disk_id unless config_data[disk_id]
        end

        raise Error, "No available #{interface} slots"
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
