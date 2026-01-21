# frozen_string_literal: true

module Proxmox
  class Authentication
    attr_reader :username, :token_name, :token_value, :password

    def initialize(username: nil, password: nil, token_name: nil, token_value: nil)
      @username = username || ENV.fetch('PROXMOX_USERNAME', nil)
      @password = password || ENV.fetch('PROXMOX_PASSWORD', nil)
      @token_name = token_name || ENV.fetch('PROXMOX_TOKEN_NAME', nil)
      @token_value = token_value || ENV.fetch('PROXMOX_TOKEN_VALUE', nil)

      validate!
    end

    def headers
      if token_auth?
        { 'Authorization' => "PVEAPIToken=#{@token_name}=#{@token_value}" }
      else
        {}
      end
    end

    def token_auth?
      !@token_name.nil? && !@token_value.nil?
    end

    def password_auth?
      !@username.nil? && !@password.nil?
    end

    private

    def validate!
      if !token_auth? && !password_auth?
        raise AuthenticationError, 'Either token credentials or username/password must be provided'
      end

      if token_auth? && (@token_name.empty? || @token_value.empty?)
        raise AuthenticationError, 'Token name and value cannot be empty'
      end

      return unless password_auth? && (@username.empty? || @password.empty?)

      raise AuthenticationError, 'Username and password cannot be empty'
    end
  end
end
