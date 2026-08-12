#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'

SITE_ROOT = File.expand_path('..', __dir__)
MODULE_ROOT = File.join(SITE_ROOT, 'node_modules')
VENDOR_ROOT = File.join(SITE_ROOT, 'static', 'vendor')

def copy(source, destination)
  raise "missing dependency asset: #{source}" unless File.exist?(source)

  FileUtils.mkdir_p(File.dirname(destination))
  FileUtils.cp_r(source, destination)
end

FileUtils.rm_rf(VENDOR_ROOT)
FileUtils.mkdir_p(VENDOR_ROOT)

copy(File.join(SITE_ROOT, 'scripts', 'assets', 'fonts.css'), File.join(VENDOR_ROOT, 'fonts', 'fonts.css'))

%w[
  lato/lato-latin-300-normal.woff2
  lato/lato-latin-400-normal.woff2
  lato/lato-latin-700-normal.woff2
  roboto/roboto-latin-400-normal.woff2
  roboto/roboto-latin-700-normal.woff2
  roboto-mono/roboto-mono-latin-400-normal.woff2
].each do |font|
  package, filename = font.split('/', 2)
  source = File.join(MODULE_ROOT, '@fontsource', package, 'files', filename)
  copy(source, File.join(VENDOR_ROOT, 'fonts', 'files', filename))
end

fontawesome_root = File.join(MODULE_ROOT, '@fortawesome', 'fontawesome-free')
copy(File.join(fontawesome_root, 'css', 'all.min.css'), File.join(VENDOR_ROOT, 'fontawesome', 'css', 'all.min.css'))
copy(File.join(fontawesome_root, 'webfonts'), File.join(VENDOR_ROOT, 'fontawesome', 'webfonts'))

academicons_root = File.join(MODULE_ROOT, 'academicons')
copy(File.join(academicons_root, 'css', 'academicons.min.css'), File.join(VENDOR_ROOT, 'academicons', 'css', 'academicons.min.css'))
copy(File.join(academicons_root, 'fonts'), File.join(VENDOR_ROOT, 'academicons', 'fonts'))

leaflet_root = File.join(MODULE_ROOT, 'leaflet', 'dist')
copy(File.join(leaflet_root, 'leaflet.css'), File.join(VENDOR_ROOT, 'leaflet', 'leaflet.css'))
copy(File.join(leaflet_root, 'leaflet.js'), File.join(VENDOR_ROOT, 'leaflet', 'leaflet.js'))
copy(File.join(leaflet_root, 'images'), File.join(VENDOR_ROOT, 'leaflet', 'images'))

puts "Vendored frontend assets prepared in #{VENDOR_ROOT}."
