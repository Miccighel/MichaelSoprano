#!/usr/bin/env ruby
# frozen_string_literal: true

require 'digest'
require 'json'

root = File.expand_path('..', __dir__)
manifest = JSON.parse(File.read(File.join(root, 'data/cv-sync.json')))
expected = %w[data/bibliometrics.json static/media/CVs/Curriculum_Vitae_EN.pdf static/media/CVs/Curriculum_Vitae_IT.pdf]
abort 'Invalid CV sync manifest' unless manifest['schema'] == 1 && manifest.fetch('files').keys.sort == expected.sort
expected.each do |path|
  abort "CV/data mismatch: #{path}. Rebuild with build_all.sh --sync-website." unless
    Digest::SHA256.file(File.join(root, path)).hexdigest == manifest['files'][path]
end
puts 'CV synchronization checked: both PDFs and bibliometric data match the same export.'
