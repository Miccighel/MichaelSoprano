#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

ROOT = File.expand_path('..', __dir__)
CONTENT_GLOBS = %w[publications events blog].freeze
LINK_TYPES = {
  'url_pdf' => 'pdf',
  'url_slides' => 'slides',
  'url_video' => 'video'
}.freeze

def update_front_matter(path, section)
  source = File.binread(path).force_encoding(Encoding::UTF_8)
  match = source.match(/\A---\r?\n(.*?)\r?\n---\r?\n/m)
  raise "Missing front matter: #{path}" unless match

  data = YAML.load(match[1]) || {}
  data = data.transform_keys(&:to_s)

  if section == 'publications'
    publication = data['publication']
    data['publication'] = { 'name' => publication } if publication.is_a?(String)

    doi = data.delete('doi')
    if doi
      data['hugoblox'] ||= {}
      data['hugoblox']['ids'] ||= {}
      data['hugoblox']['ids']['doi'] = doi
    end
  elsif section == 'events'
    data['event_name'] = data.delete('event') if data.key?('event')
    data['event_start'] = data.delete('date') if data.key?('date')
    data['event_end'] = data.delete('date_end') if data.key?('date_end')
    data['event_all_day'] = data.delete('all_day') if data.key?('all_day')
  end

  links = Array(data['links'])
  LINK_TYPES.each do |legacy_key, type|
    url = data.delete(legacy_key)
    links << { 'type' => type, 'url' => url } if url && !url.empty?
  end
  data['links'] = links unless links.empty?

  front_matter = YAML.dump(data)
  body = source[match.end(0)..]
  File.write(path, "#{front_matter}---\n#{body}")
end

CONTENT_GLOBS.each do |section|
  Dir.glob(File.join(ROOT, 'content', section, '**', 'index.md')).sort.each do |path|
    update_front_matter(path, section)
  end
end
