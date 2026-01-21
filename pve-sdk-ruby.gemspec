# frozen_string_literal: true

require_relative 'lib/proxmox/version'

Gem::Specification.new do |spec|
  spec.name          = 'pve-sdk-ruby'
  spec.version       = Proxmox::VERSION
  spec.authors       = ['Proxmox Ruby Contributors']
  spec.email         = ['']

  spec.summary       = 'Ruby wrapper for Proxmox VE API'
  spec.description   = 'A minimal, focused Ruby library for interacting with Proxmox VE API, ' \
                       'covering clusters, nodes, VMs, containers, and storage management.'
  spec.homepage      = 'https://github.com/stiwa-uejo/pve-sdk-ruby'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.glob('{lib}/**/*') + %w[README.md LICENSE CHANGELOG.md]
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'faraday', '~> 2.14'
  spec.add_dependency 'json', '~> 2.6'
end
