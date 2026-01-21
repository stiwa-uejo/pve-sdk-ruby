# frozen_string_literal: true

require 'json'

module Proxmox
  class Response
    attr_reader :raw_response, :status, :headers, :body

    def initialize(response)
      @raw_response = response
      @status = response.status
      @headers = response.headers
      @body = parse_body(response.body)
    end

    def success?
      (200..299).include?(@status)
    end

    def data
      @body.is_a?(Hash) ? @body['data'] : @body
    end

    def errors
      return [] unless @body.is_a?(Hash)

      @body['errors'] || []
    end

    def error_message
      return nil if success?

      if @body.is_a?(Hash)
        errors = @body['errors']
        if errors.is_a?(Array)
          errors.join(', ')
        elsif errors.is_a?(Hash)
          errors.values.join(', ')
        else
          @body['message'] || "HTTP #{@status}"
        end
      else
        "HTTP #{@status}"
      end
    end

    private

    def parse_body(body)
      return {} if body.nil? || body.empty?

      JSON.parse(body)
    rescue JSON::ParserError => e
      raise Proxmox::Error, "Invalid JSON response: #{e.message}"
    end
  end
end
