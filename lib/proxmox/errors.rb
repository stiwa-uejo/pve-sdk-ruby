# frozen_string_literal: true

module Proxmox
  class Error < StandardError
    attr_reader :response, :status_code

    def initialize(message, response: nil, status_code: nil)
      super(message)
      @response = response
      @status_code = status_code
    end
  end

  class AuthenticationError < Error; end
  class ConnectionError < Error; end
  class NotFoundError < Error; end
  class ValidationError < Error; end
  class APIError < Error; end
  class TimeoutError < Error; end
  class SSLError < Error; end
end
