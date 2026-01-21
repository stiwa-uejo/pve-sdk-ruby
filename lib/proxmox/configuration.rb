# frozen_string_literal: true

module Proxmox
  class Configuration
    attr_accessor :host, :port, :verify_ssl, :timeout, :logger, :log_level

    def initialize
      @host = ENV.fetch('PROXMOX_HOST', nil)
      @port = ENV.fetch('PROXMOX_PORT', 8006).to_i
      @verify_ssl = ENV.fetch('PROXMOX_VERIFY_SSL', 'true') == 'true'
      @timeout = ENV.fetch('PROXMOX_TIMEOUT', 30).to_i
      @logger = nil
      @log_level = :info
    end

    def validate!
      raise ValidationError, 'Host is required' if host.nil? || host.empty?
      raise ValidationError, 'Port must be a positive integer' if port <= 0
      raise ValidationError, 'Timeout must be a positive integer' if timeout <= 0
    end

    def merge(options = {})
      new_config = self.class.new
      %i[host port verify_ssl timeout logger log_level].each do |key|
        value = options.key?(key) ? options[key] : send(key)
        new_config.send("#{key}=", value)
      end
      new_config
    end
  end
end
