#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rbconfig'

SITE_ROOT = File.expand_path('..', __dir__)
RUBY = RbConfig.ruby
PAGEFIND = File.join(SITE_ROOT, 'node_modules', '.bin', 'pagefind')

commands = [
  [RUBY, File.join(SITE_ROOT, 'scripts', 'vendor-assets.rb')],
  [RUBY, File.join(SITE_ROOT, 'scripts', 'check-content.rb')],
  [
    'hugo',
    '--cacheDir', File.join(SITE_ROOT, 'resources', '_cache'),
    '--gc',
    '--minify',
    '--cleanDestinationDir'
  ],
  [PAGEFIND, '--site', File.join(SITE_ROOT, 'public')]
]

commands << [RUBY, File.join(SITE_ROOT, 'scripts', 'audit-build.rb')] if ARGV.delete('--audit')
abort "Unknown argument(s): #{ARGV.join(' ')}" unless ARGV.empty?

commands.each do |command|
  puts "\n→ #{command.join(' ')}"
  abort "Command failed: #{command.first}" unless system(*command, chdir: SITE_ROOT)
end
