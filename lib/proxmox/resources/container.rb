# frozen_string_literal: true

module Proxmox
  module Resources
    class Container < Base
      attr_reader :vmid

      def initialize(client, node:, vmid:, **attrs)
        @node_name = node
        @vmid = vmid
        super(client, **attrs)
      end

      def node
        Resources::Node.new(@client, node: @node_name)
      end

      def status
        response = http_get("/api2/json/nodes/#{@node_name}/lxc/#{@vmid}/status/current")
        extract_data(response)
      end

      def config
        response = http_get("/api2/json/nodes/#{@node_name}/lxc/#{@vmid}/config")
        extract_data(response)
      end

      def start
        response = http_post("/api2/json/nodes/#{@node_name}/lxc/#{@vmid}/status/start")
        extract_data(response)
      end

      def stop
        response = http_post("/api2/json/nodes/#{@node_name}/lxc/#{@vmid}/status/stop")
        extract_data(response)
      end

      def shutdown(timeout: 60)
        response = http_post("/api2/json/nodes/#{@node_name}/lxc/#{@vmid}/status/shutdown",
                        params: { timeout: timeout })
        extract_data(response)
      end

      def reboot
        response = http_post("/api2/json/nodes/#{@node_name}/lxc/#{@vmid}/status/reboot")
        extract_data(response)
      end

      def update(params = {}, **kwargs)
        merged_params = params.merge(kwargs)
        response = http_put("/api2/json/nodes/#{@node_name}/lxc/#{@vmid}/config", params: merged_params)
        extract_data(response)
      end

      def delete
        response = http_delete("/api2/json/nodes/#{@node_name}/lxc/#{@vmid}")
        extract_data(response)
      end

      def snapshots
        response = http_get("/api2/json/nodes/#{@node_name}/lxc/#{@vmid}/snapshot")
        extract_data(response)
      end

      def create_snapshot(name:, description: nil)
        params = { snapname: name }
        params[:description] = description if description
        response = http_post("/api2/json/nodes/#{@node_name}/lxc/#{@vmid}/snapshot", params: params)
        extract_data(response)
      end

      def delete_snapshot(name)
        response = http_delete("/api2/json/nodes/#{@node_name}/lxc/#{@vmid}/snapshot/#{name}")
        extract_data(response)
      end

      def volumes
        config_data = config
        volume_list = []

        if config_data['rootfs']
          rootfs_attrs = parse_volume_config(config_data['rootfs'])
          volume_list << Resources::Disk.new(
            @client,
            node: @node_name,
            vmid: @vmid,
            disk_id: 'rootfs',
            **rootfs_attrs
          )
        end

        256.times do |i|
          mp_key = "mp#{i}"
          next unless config_data[mp_key]

          mp_attrs = parse_volume_config(config_data[mp_key])
          volume_list << Resources::Disk.new(
            @client,
            node: @node_name,
            vmid: @vmid,
            disk_id: mp_key,
            **mp_attrs
          )
        end

        volume_list
      end

      def resize_rootfs(size:)
        response = http_put(
          "/api2/json/nodes/#{@node_name}/lxc/#{@vmid}/resize",
          params: { disk: 'rootfs', size: size }
        )
        extract_data(response)
      end

      def resize_mountpoint(mp_id:, size:)
        response = http_put(
          "/api2/json/nodes/#{@node_name}/lxc/#{@vmid}/resize",
          params: { disk: mp_id, size: size }
        )
        extract_data(response)
      end

      def move_volume(volume:, storage:, delete: false)
        params = {
          volume: volume,
          storage: storage,
          delete: delete ? 1 : 0
        }

        response = http_post("/api2/json/nodes/#{@node_name}/lxc/#{@vmid}/move_volume", params: params)
        extract_data(response)
      end

      def add_mountpoint(mp_id:, storage:, size:, path:, **options)
        mp_config = build_mountpoint_config(storage, size, path, options)

        response = http_put(
          "/api2/json/nodes/#{@node_name}/lxc/#{@vmid}/config",
          params: { mp_id.to_sym => mp_config }
        )
        extract_data(response)
      end

      def remove_mountpoint(mp_id)
        response = http_put(
          "/api2/json/nodes/#{@node_name}/lxc/#{@vmid}/config",
          params: { delete: mp_id }
        )
        extract_data(response)
      end

      private

      def parse_volume_config(volume_string)
        parts = volume_string.split(',')
        volume = parts.shift

        attrs = { volid: volume }

        if volume.include?(':')
          storage, vol_name = volume.split(':', 2)
          attrs[:storage] = storage
          attrs[:volume] = vol_name
        end

        parts.each do |part|
          key, value = part.split('=', 2)
          attrs[key.to_sym] = value if key && value
        end

        attrs
      end

      def build_mountpoint_config(storage, size, path, options)
        clean_size = size.to_s.gsub(/[GMK]$/i, '')

        config_parts = ["#{storage}:#{clean_size}", "mp=#{path}"]

        config_parts << 'backup=1' if options[:backup]
        config_parts << 'ro=1' if options[:readonly]

        config_parts.join(',')
      end
    end
  end
end
