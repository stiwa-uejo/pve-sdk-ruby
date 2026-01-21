# frozen_string_literal: true

module Proxmox
  class Client
    attr_reader :connection, :authentication

    def initialize(host: nil, port: 8006, username: nil, password: nil,
                   token_name: nil, token_value: nil, verify_ssl: true, timeout: 30)
      @host = host || Proxmox.configuration&.host
      @port = port
      @verify_ssl = verify_ssl
      @timeout = timeout

      raise ValidationError, 'Host is required' if @host.nil? || @host.empty?

      @connection = Connection.new(
        host: @host,
        port: @port,
        verify_ssl: @verify_ssl,
        timeout: @timeout
      )

      @authentication = Authentication.new(
        username: username,
        password: password,
        token_name: token_name,
        token_value: token_value
      )

      return unless @authentication.password_auth?

      @connection.authenticate(
        username: @authentication.username,
        password: @authentication.password
      )
    end

    def cluster
      @cluster ||= Resources::Cluster.new(self)
    end

    def nodes
      Resources::Node.new(self)
    end

    def node(node_name)
      Resources::Node.new(self, node: node_name).load_details
    end

    def vms
      cluster.resources(type: 'vm')
    end

    def vm(name_or_node, vmid = nil)
      if vmid
        Resources::VM.new(self, node: name_or_node, vmid: vmid).load_details
      else
        vm_obj = vms.find { |v| v.name == name_or_node }
        raise NotFoundError, "VM '#{name_or_node}' not found" unless vm_obj

        vm_obj
      end
    end

    def containers
      cluster.resources.select { |r| r.is_a?(Resources::Container) }
    end

    def container(node, vmid)
      Resources::Container.new(self, node: node, vmid: vmid)
    end

    def storage(node, storage)
      Resources::Storage.new(self, node: node, storage: storage)
    end

    def disk(node, vmid, disk_id)
      Resources::Disk.new(self, node: node, vmid: vmid, disk_id: disk_id)
    end

    def request(method:, path:, params: {})
      headers = @connection.auth_headers(@authentication.headers)

      response = @connection.request(
        method: method,
        path: path,
        headers: headers,
        params: params
      )

      handle_response(response, path)
    end

    private

    def handle_response(response, path)
      case response.status
      when 200..299
        response
      when 401
        raise Proxmox::AuthenticationError, 'Authentication failed'
      when 404
        raise Proxmox::NotFoundError, "Resource not found: #{path}"
      when 400..499
        raise Proxmox::ValidationError, response.error_message || "Client error: #{response.status}"
      when 500..599
        raise Proxmox::APIError, response.error_message || "Server error: #{response.status}"
      else
        raise Proxmox::Error, "Unexpected response: #{response.status}"
      end
    end
  end
end
