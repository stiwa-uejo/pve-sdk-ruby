# frozen_string_literal: true

module Proxmox
  module Resources
    # Base class for all Proxmox resources
    class Base
      attr_reader :client, :attributes

      def initialize(client, **attrs)
        @client = client
        @attributes = attrs
        populate_attributes if @attributes.any?
      end

      # Convert hash keys to accessible attributes
      def populate_attributes
        @attributes.each do |key, value|
          # Sanitize key to be a valid Ruby instance variable name
          sanitized_key = key.to_s.tr('-', '_')
          instance_variable_set("@#{sanitized_key}", value)

          # Define attr_reader for this attribute if not already defined
          singleton_class.class_eval { attr_reader sanitized_key.to_sym } unless respond_to?(sanitized_key)
        end
      end

      # Convert object back to hash
      # @return [Hash]
      def to_h
        @attributes.dup
      end

      # Allow hash-like access for compatibility
      # @param key [String, Symbol] Attribute key
      # @return [Object, nil]
      def [](key)
        @attributes[key.to_s]
      end

      # Inspect method for better debugging
      # @return [String]
      def inspect
        attrs = @attributes.map { |k, v| "#{k}=#{v.inspect}" }.join(', ')
        "#<#{self.class.name} #{attrs}>"
      end

      protected

      # Execute a GET request
      # @param path [String] API path
      # @param params [Hash] Query parameters
      # @return [Response]
      def http_get(path, params: {})
        @client.request(method: :get, path: path, params: params)
      end

      # Execute a POST request
      # @param path [String] API path
      # @param params [Hash] Request parameters
      # @return [Response]
      def http_post(path, params: {})
        @client.request(method: :post, path: path, params: params)
      end

      # Execute a PUT request
      # @param path [String] API path
      # @param params [Hash] Request parameters
      # @return [Response]
      def http_put(path, params: {})
        @client.request(method: :put, path: path, params: params)
      end

      # Execute a DELETE request
      # @param path [String] API path
      # @param params [Hash] Request parameters
      # @return [Response]
      def http_delete(path, params: {})
        @client.request(method: :delete, path: path, params: params)
      end

      # Build an API path from segments
      # @param segments [Array<String>] Path segments
      # @return [String]
      def build_path(*segments)
        segments.compact.map(&:to_s).join('/')
      end

      # Validate required parameters
      # @param params [Hash] Parameters hash
      # @param keys [Array<Symbol>] Required keys
      # @raise [ValidationError] if any required key is missing
      def validate_required!(params, *keys)
        missing = keys.select { |key| params[key].nil? || params[key].to_s.empty? }
        return if missing.empty?

        raise ValidationError, "Missing required parameters: #{missing.join(', ')}"
      end

      # Extract data from response
      # @param response [Response]
      # @return [Hash, Array, nil]
      def extract_data(response)
        response.data
      end
    end
  end
end
