# frozen_string_literal: true

require 'proxmox/version'
require 'proxmox/errors'
require 'proxmox/configuration'
require 'proxmox/authentication'
require 'proxmox/connection'
require 'proxmox/response'
require 'proxmox/client'

# Resources
require 'proxmox/resources/base'
require 'proxmox/resources/cluster'
require 'proxmox/resources/node'
require 'proxmox/resources/vm'
require 'proxmox/resources/container'
require 'proxmox/resources/storage'
require 'proxmox/resources/disk'

module Proxmox
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  def self.reset_configuration!
    self.configuration = Configuration.new
  end
end
