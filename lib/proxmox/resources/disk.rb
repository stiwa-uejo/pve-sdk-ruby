# frozen_string_literal: true

module Proxmox
  module Resources
    class Disk < Base
      attr_reader :vmid, :disk_id, :storage, :size, :format, :type

      def initialize(client, node:, vmid:, disk_id:, **attrs)
        @node_name = node
        @vmid = vmid
        @disk_id = disk_id
        @type = determine_type(disk_id)
        super(client, **attrs)
      end

      def node
        Resources::Node.new(@client, node: @node_name)
      end

      def resize(size:)
        case @type
        when :vm_disk
          resize_vm_disk(size)
        when :container_rootfs, :container_mountpoint
          resize_container_volume(size)
        else
          raise Error, "Unknown disk type: #{@type}"
        end
      end

      def move(storage:, delete: false)
        case @type
        when :vm_disk
          move_vm_disk(storage, delete)
        when :container_rootfs, :container_mountpoint
          move_container_volume(storage, delete)
        else
          raise Error, "Unknown disk type: #{@type}"
        end
      end

      def info
        if @storage && volume_id
          storage_obj = Resources::Storage.new(@client, node: @node_name, storage: @storage)
          storage_obj.volume_info(volume_id)
        else
          to_h
        end
      end

      def delete
        case @type
        when :vm_disk
          vm = Resources::VM.new(@client, node: @node_name, vmid: @vmid)
          vm.remove_disk(@disk_id)
        when :container_mountpoint
          container = Resources::Container.new(@client, node: @node_name, vmid: @vmid)
          container.remove_mountpoint(@disk_id)
        else
          raise Error, "Cannot delete #{@type}"
        end
      end

      def volume_id
        @attributes['volid'] || @attributes['volume']
      end

      def vm_disk?
        @type == :vm_disk
      end

      def container_volume?
        %i[container_rootfs container_mountpoint].include?(@type)
      end

      def self.parse_config(disk_string)
        parts = disk_string.split(',')
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

      def self.build_config(storage, size, options)
        clean_size = size.to_s.gsub(/[GMK]$/i, '')

        config_parts = ["#{storage}:#{clean_size}"]

        config_parts << "format=#{options[:format]}" if options[:format]
        config_parts << "cache=#{options[:cache]}" if options[:cache]
        config_parts << 'ssd=1' if options[:ssd]
        config_parts << 'discard=on' if options[:discard]

        config_parts.join(',')
      end

      private

      def determine_type(disk_id)
        case disk_id
        when /^(ide|scsi|virtio|sata)\d+$/
          :vm_disk
        when 'rootfs'
          :container_rootfs
        when /^mp\d+$/
          :container_mountpoint
        else
          :unknown
        end
      end

      def resize_vm_disk(size)
        response = http_put(
          "/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/resize",
          params: { disk: @disk_id, size: size }
        )
        extract_data(response)
      end

      def resize_container_volume(size)
        response = http_put(
          "/api2/json/nodes/#{@node_name}/lxc/#{@vmid}/resize",
          params: { disk: @disk_id, size: size }
        )
        extract_data(response)
      end

      def move_vm_disk(storage, delete)
        params = {
          disk: @disk_id,
          storage: storage,
          delete: delete ? 1 : 0
        }
        response = http_post("/api2/json/nodes/#{@node_name}/qemu/#{@vmid}/move_disk", params: params)
        extract_data(response)
      end

      def move_container_volume(storage, delete)
        params = {
          volume: @disk_id,
          storage: storage,
          delete: delete ? 1 : 0
        }
        response = http_post("/api2/json/nodes/#{@node_name}/lxc/#{@vmid}/move_volume", params: params)
        extract_data(response)
      end
    end
  end
end
