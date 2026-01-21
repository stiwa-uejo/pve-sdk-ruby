# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]

desc 'Run RSpec tests'
task test: :spec

desc 'Generate YARD documentation'
task :doc do
  sh 'yard doc'
end

desc 'Open documentation in browser'
task doc_open: :doc do
  sh 'open doc/index.html'
end

desc 'Run console with library loaded'
task :console do
  require 'irb'
  require 'proxmox'
  ARGV.clear
  IRB.start
end
