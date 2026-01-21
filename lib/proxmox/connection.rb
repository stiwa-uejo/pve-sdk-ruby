# frozen_string_literal: true

require 'faraday'
require 'faraday/net_http'
require 'json'
require 'openssl'

module Proxmox
  class Connection
    attr_reader :host, :port, :verify_ssl, :timeout

    def initialize(host:, port: 8006, verify_ssl: true, timeout: 30)
      @host = host
      @port = port
      @verify_ssl = verify_ssl
      @timeout = timeout
      @ticket = nil
      @csrf_token = nil

      @connection = Faraday.new(url: base_url, ssl: { verify: verify_ssl }) do |f|
        f.request :url_encoded
        f.adapter :net_http
        f.options.timeout = timeout
        f.options.open_timeout = timeout
      end
    end

    def request(method:, path:, headers: {}, params: {})
      response = @connection.send(method, path) do |req|
        req.headers.merge!(headers)
        if method == :get
          req.params = params
        else
          req.body = params
        end
      end

      Response.new(response)
    rescue Faraday::TimeoutError => e
      raise Proxmox::TimeoutError, "Request timeout: #{e.message}"
    rescue Faraday::ConnectionFailed => e
      raise Proxmox::ConnectionError, "Connection failed: #{e.message}"
    rescue Faraday::SSLError => e
      raise Proxmox::SSLError, "SSL verification failed: #{e.message}"
    rescue Faraday::Error => e
      raise Proxmox::Error, "Request failed: #{e.message}"
    end

    def authenticate(username:, password:)
      response = request(
        method: :post,
        path: '/api2/json/access/ticket',
        params: { username: username, password: password }
      )

      raise Proxmox::AuthenticationError, "Authentication failed: #{response.error_message}" unless response.success?

      data = response.data
      @ticket = data['ticket']
      @csrf_token = data['CSRFPreventionToken']

      { ticket: @ticket, csrf_token: @csrf_token }
    end

    def auth_headers(auth_headers = {})
      if @ticket && @csrf_token
        {
          'Cookie' => "PVEAuthCookie=#{@ticket}",
          'CSRFPreventionToken' => @csrf_token
        }
      else
        auth_headers
      end
    end

    private

    def base_url
      "https://#{@host}:#{@port}"
    end
  end
end
