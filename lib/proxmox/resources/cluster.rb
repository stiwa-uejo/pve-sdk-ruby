# frozen_string_literal: true

module Proxmox
  module Resources
    class Cluster < Base
      class GenericResource < Base
        attr_reader :status, :pid, :exitstatus
      end

      def name
        cluster_info = status.find { |item| item.respond_to?(:type) && item.type == 'cluster' }
        cluster_info&.name
      end

      def nodes
        resources(type: 'node')
      end

      def status
        response = http_get('/api2/json/cluster/status')
        data = extract_data(response)

        data.map do |item|
          case item['type']
          when 'node'
            Node.new(@client, node: item['name'], **item)
          else
            GenericResource.new(@client, **item)
          end
        end
      end

      def resources(type: nil)
        params = type ? { type: type } : {}
        response = http_get('/api2/json/cluster/resources', params: params)
        data = extract_data(response)

        data.map do |resource|
          case resource['type']
          when 'qemu'
            VM.new(@client, node: resource['node'], vmid: resource['vmid'], **resource)
          when 'lxc'
            Container.new(@client, node: resource['node'], vmid: resource['vmid'], **resource)
          when 'node'
            Node.new(@client, node: resource['node'], **resource)
          when 'storage'
            Storage.new(@client, node: resource['node'], storage: resource['storage'], **resource)
          else
            GenericResource.new(@client, **resource)
          end
        end
      end

      def tasks
        response = http_get('/api2/json/cluster/tasks')
        data = extract_data(response)
        data.map { |item| GenericResource.new(@client, **item) }
      end

      def options
        response = http_get('/api2/json/cluster/options')
        extract_data(response)
      end

      def update_options(**params)
        response = http_put('/api2/json/cluster/options', params: params)
        extract_data(response)
      end

      def next_vmid
        response = http_get('/api2/json/cluster/nextid')
        extract_data(response)
      end

      def backup_jobs
        response = http_get('/api2/json/cluster/backup')
        data = extract_data(response)
        data.map { |item| GenericResource.new(@client, **item) }
      end

      def backup_job(id)
        response = http_get("/api2/json/cluster/backup/#{id}")
        extract_data(response)
      end

      def create_backup_job(**params)
        validate_required!(params, :schedule, :storage)
        response = http_post('/api2/json/cluster/backup', params: params)
        extract_data(response)
      end

      def update_backup_job(id, **params)
        response = http_put("/api2/json/cluster/backup/#{id}", params: params)
        extract_data(response)
      end

      def delete_backup_job(id)
        response = http_delete("/api2/json/cluster/backup/#{id}")
        extract_data(response)
      end

      def ha_resources
        response = http_get('/api2/json/cluster/ha/resources')
        data = extract_data(response)
        data.map { |item| GenericResource.new(@client, **item) }
      end

      def ha_resource(sid)
        response = http_get("/api2/json/cluster/ha/resources/#{sid}")
        extract_data(response)
      end

      def create_ha_resource(**params)
        validate_required!(params, :sid)
        response = http_post('/api2/json/cluster/ha/resources', params: params)
        extract_data(response)
      end

      def update_ha_resource(sid, **params)
        response = http_put("/api2/json/cluster/ha/resources/#{sid}", params: params)
        extract_data(response)
      end

      def delete_ha_resource(sid)
        response = http_delete("/api2/json/cluster/ha/resources/#{sid}")
        extract_data(response)
      end

      def ha_status
        response = http_get('/api2/json/cluster/ha/status/current')
        extract_data(response)
      end

      def firewall_rules
        response = http_get('/api2/json/cluster/firewall/rules')
        data = extract_data(response)
        data.map { |item| GenericResource.new(@client, **item) }
      end

      def create_firewall_rule(**params)
        validate_required!(params, :type, :action)
        response = http_post('/api2/json/cluster/firewall/rules', params: params)
        extract_data(response)
      end

      def replications
        response = http_get('/api2/json/cluster/replication')
        data = extract_data(response)
        data.map { |item| GenericResource.new(@client, **item) }
      end

      def replication(id)
        response = http_get("/api2/json/cluster/replication/#{id}")
        extract_data(response)
      end

      def create_replication(**params)
        validate_required!(params, :id, :target)
        response = http_post('/api2/json/cluster/replication', params: params)
        extract_data(response)
      end

      def update_replication(id, **params)
        response = http_put("/api2/json/cluster/replication/#{id}", params: params)
        extract_data(response)
      end

      def delete_replication(id)
        response = http_delete("/api2/json/cluster/replication/#{id}")
        extract_data(response)
      end
    end
  end
end
