# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
end

require 'proxmox'
require 'webmock/rspec'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.filter_sensitive_data('<PROXMOX_HOST>') { ENV.fetch('PROXMOX_HOST', nil) }
  config.filter_sensitive_data('<PROXMOX_TOKEN_NAME>') { ENV.fetch('PROXMOX_TOKEN_NAME', nil) }
  config.filter_sensitive_data('<PROXMOX_TOKEN_VALUE>') { ENV.fetch('PROXMOX_TOKEN_VALUE', nil) }
  config.filter_sensitive_data('<PROXMOX_PASSWORD>') { ENV.fetch('PROXMOX_PASSWORD', nil) }
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end
