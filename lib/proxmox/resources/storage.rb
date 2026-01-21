# frozen_string_literal: true

module Proxmox
  module Resources
    class Storage < Base
      attr_reader :storage

      def initialize(client, node:, storage:, **attrs)
        @node_name = node
        @storage = storage
        super(client, **attrs)
      end

      def node
        Resources::Node.new(@client, node: @node_name)
      end

      def status
        response = http_get("/api2/json/nodes/#{@node_name}/storage/#{@storage}/status")
        extract_data(response)
      end

      def content(type: nil)
        params = type ? { content: type } : {}
        response = http_get("/api2/json/nodes/#{@node_name}/storage/#{@storage}/content", params: params)
        extract_data(response)
      end

      def upload(filename:, _content:, content_type: 'iso')
        params = {
          filename: filename,
          content: content_type
        }
        # NOTE: Actual file upload would require multipart/form-data
        # This is a simplified version
        response = http_post("/api2/json/nodes/#{@node_name}/storage/#{@storage}/upload", params: params)
        extract_data(response)
      end

      def delete_volume(volume)
        response = http_delete("/api2/json/nodes/#{@node_name}/storage/#{@storage}/content/#{volume}")
        extract_data(response)
      end

      def allocate_disk(vmid:, filename:, size:, format: 'raw')
        params = {
          vmid: vmid,
          filename: filename,
          size: size,
          format: format
        }

        response = http_post("/api2/json/nodes/#{@node_name}/storage/#{@storage}/content", params: params)
        extract_data(response)
      end

      def volume_info(volume)
        encoded_volume = CGI.escape(volume)
        response = http_get("/api2/json/nodes/#{@node_name}/storage/#{@storage}/content/#{encoded_volume}")
        extract_data(response)
      end

      def vm_volumes(vmid)
        all_content = content(type: 'images')
        all_content.select { |item| item['vmid'] == vmid }
      end
    end
  end
end
