# frozen_string_literal: true

module Proxmox
  module Resources
    class Node < Base
      attr_reader :node

      def initialize(client, node: nil, **attrs)
        @node_name = node || attrs['node']
        super(client, **attrs)
      end

      def load_details
        validate_node!
        stat = status
        @attributes.merge!(stat) if stat.is_a?(Hash)
        populate_attributes
        self
      end

      def name
        @node_name
      end

      def online?
        @attributes['status'] == 'online'
      end

      def offline?
        @attributes['status'] == 'offline'
      end

      def cluster
        Resources::Cluster.new(@client)
      end

      def ip
        return @ip if @ip

        cluster_node = cluster.status.find { |n| n.is_a?(Node) && n.name == name }
        if cluster_node.respond_to?(:ip)
          @ip = cluster_node.ip
          return @ip
        end

        nil
      end

      def network_interfaces
        validate_node!
        response = http_get("/api2/json/nodes/#{@node_name}/network")
        extract_data(response)
      end

      def list
        response = http_get('/api2/json/nodes')
        data = extract_data(response)
        data.map { |node_data| Node.new(@client, **node_data) }
      end

      def status
        validate_node!
        response = http_get("/api2/json/nodes/#{@node_name}/status")
        extract_data(response)
      end

      def version
        validate_node!
        response = http_get("/api2/json/nodes/#{@node_name}/version")
        extract_data(response)
      end

      def vms
        validate_node!
        response = http_get("/api2/json/nodes/#{@node_name}/qemu")
        data = extract_data(response)
        data.map { |vm_data| VM.new(@client, node: @node_name, vmid: vm_data['vmid'], **vm_data) }
      end

      def containers
        validate_node!
        response = http_get("/api2/json/nodes/#{@node_name}/lxc")
        data = extract_data(response)
        data.map { |ct_data| Container.new(@client, node: @node_name, vmid: ct_data['vmid'], **ct_data) }
      end

      def storage
        validate_node!
        response = http_get("/api2/json/nodes/#{@node_name}/storage")
        data = extract_data(response)
        data.map do |storage_data|
          Storage.new(@client, node: @node_name, storage: storage_data['storage'], **storage_data)
        end
      end

      def tasks(limit: nil, start: nil, source: nil, errors: nil, userfilter: nil, vmid: nil)
        validate_node!
        params = {}
        params[:limit] = limit if limit
        params[:start] = start if start
        params[:source] = source if source
        params[:errors] = errors ? 1 : 0 unless errors.nil?
        params[:userfilter] = userfilter if userfilter
        params[:vmid] = vmid if vmid

        response = http_get("/api2/json/nodes/#{@node_name}/tasks", params: params)
        extract_data(response)
      end

      def task_status(upid)
        validate_node!
        raise ValidationError, 'UPID is required' if upid.nil? || upid.empty?

        response = http_get("/api2/json/nodes/#{@node_name}/tasks/#{upid}/status")
        extract_data(response)
      end

      def task_log(upid, limit: nil, start: nil)
        validate_node!
        raise ValidationError, 'UPID is required' if upid.nil? || upid.empty?

        params = {}
        params[:limit] = limit if limit
        params[:start] = start if start

        response = http_get("/api2/json/nodes/#{@node_name}/tasks/#{upid}/log", params: params)
        extract_data(response)
      end

      def stop_task(upid)
        validate_node!
        raise ValidationError, 'UPID is required' if upid.nil? || upid.empty?

        response = http_delete("/api2/json/nodes/#{@node_name}/tasks/#{upid}")
        extract_data(response)
      end

      private

      def validate_node!
        raise ValidationError, 'Node name is required' if @node_name.nil? || @node_name.empty?
      end
    end
  end
end
