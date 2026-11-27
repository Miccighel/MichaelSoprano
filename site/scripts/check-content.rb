#!/usr/bin/env ruby
# frozen_string_literal: true

require 'date'
require 'time'
require 'yaml'

ROOT = File.expand_path('..', __dir__)
SECTIONS = {
  'publications' => %w[title date authors publication_types publication],
  'events' => %w[title date authors event_name event_start event_end],
  'blog' => %w[title date authors]
}.freeze
PUBLICATION_TYPES = %w[
  paper-conference article-journal article report book chapter thesis patent
].freeze

def blank?(value)
  value.nil? || value == '' || value == [] || value == {}
end

def load_page(path)
  source = File.binread(path).force_encoding(Encoding::UTF_8)
  match = source.match(/\A---\r?\n(.*?)\r?\n---\r?\n/m)
  raise 'missing YAML front matter' unless match

  YAML.safe_load(
    match[1],
    permitted_classes: [Date, Time],
    aliases: true
  ) || {}
end

errors = []
warnings = []
counts = {}

topic_labels = YAML.safe_load_file(File.join(ROOT, 'data', 'topics.yaml')).fetch('labels')
legacy_topic_slugs = Dir.glob(File.join(ROOT, 'content', 'tags', '*', '_index.md')).flat_map do |path|
  Array(load_page(path)['aliases']).map { |url| url.split('/').last }
end

icon_path = File.join(ROOT, 'assets', 'media', 'icon.png')
if !File.file?(icon_path)
  errors << 'assets/media/icon.png: missing favicon source'
elsif File.size(icon_path).zero?
  errors << 'assets/media/icon.png: favicon source is empty'
end

fallback_icon_path = File.join(ROOT, 'static', 'favicon.ico')
if !File.file?(fallback_icon_path)
  errors << 'static/favicon.ico: missing compatibility favicon'
elsif File.size(fallback_icon_path).zero?
  errors << 'static/favicon.ico: compatibility favicon is empty'
end

SECTIONS.each do |section, required_fields|
  paths = Dir.glob(File.join(ROOT, 'content', section, '*', 'index.md')).sort
  counts[section] = paths.length
  slugs = paths.map { |path| File.basename(File.dirname(path)) }
  slugs.group_by(&:downcase).each_value do |duplicates|
    errors << "duplicate slug in #{section}: #{duplicates.join(', ')}" if duplicates.length > 1
  end

  paths.each do |path|
    relative_path = path.delete_prefix("#{ROOT}/")
    begin
      data = load_page(path)
    rescue StandardError => e
      errors << "#{relative_path}: #{e.message}"
      next
    end

    required_fields.each do |field|
      errors << "#{relative_path}: missing #{field}" if blank?(data[field])
    end

    warnings << "#{relative_path}: still marked as draft" if data['draft'] == true

    tags = Array(data['tags'])
    errors << "#{relative_path}: duplicate topics" unless tags.uniq.length == tags.length
    tags.each do |tag|
      unless tag.is_a?(String) && !tag.strip.empty?
        errors << "#{relative_path}: topics must be nonempty strings"
        next
      end
      key = tag.downcase.split.join('-')
      expected = topic_labels.fetch(key, tag.downcase.split.join(' '))
      errors << "#{relative_path}: use topic #{expected.inspect} instead of #{tag.inspect}" unless tag == expected
      errors << "#{relative_path}: #{tag.inspect} is a retired topic" if legacy_topic_slugs.include?(key)
    end

    if section == 'publications'
      errors << "#{relative_path}: legacy hugoblox front matter is not allowed" if data.key?('hugoblox')
      Array(data['publication_types']).each do |publication_type|
        next if PUBLICATION_TYPES.include?(publication_type)

        errors << "#{relative_path}: unsupported publication type #{publication_type.inspect}"
      end
      publication_name = data.dig('publication', 'name') if data['publication'].is_a?(Hash)
      errors << "#{relative_path}: missing publication.name" if blank?(publication_name)

      identifiers = data['identifiers']
      if identifiers && !identifiers.is_a?(Hash)
        errors << "#{relative_path}: identifiers must be a mapping"
      elsif identifiers&.key?('doi') && !blank?(identifiers['doi']) && identifiers['doi'].to_s !~ %r{\A10\.\d{4,9}/\S+\z}i
        errors << "#{relative_path}: invalid identifiers.doi"
      end
    end

    if section == 'events' && data['event_start'] && data['event_end']
      begin
        event_dates = %w[event_start event_end].map do |field|
          value = data.fetch(field).to_s
          if value.match?(/\A\d{4}-\d{2}-\d{2}\z/)
            Date.iso8601(value)
          else
            unless value.match?(/(?:Z|[+-]\d{2}:\d{2})\z/)
              errors << "#{relative_path}: #{field} needs a time zone offset"
            end
            Time.iso8601(value)
          end
        end
        start_time, end_time = event_dates
        if start_time.class != end_time.class
          errors << "#{relative_path}: event_start and event_end must use the same precision"
        elsif end_time < start_time
          errors << "#{relative_path}: event_end precedes event_start"
        end
      rescue ArgumentError
        errors << "#{relative_path}: invalid event_start or event_end"
      end
    end

    Array(data['links']).each_with_index do |link, index|
      unless link.is_a?(Hash) && !blank?(link['type']) && !blank?(link['url'])
        errors << "#{relative_path}: links[#{index}] requires type and url"
      end
    end
  end
end

home_path = File.join(ROOT, 'data', 'home.yaml')
begin
  home = YAML.safe_load(File.read(home_path), permitted_classes: [Date, Time], aliases: true) || {}
  %w[visits experience].each do |field|
    errors << "data/home.yaml: missing #{field}" if blank?(home[field])
  end
rescue StandardError => e
  errors << "data/home.yaml: #{e.message}"
end

author_path = File.join(ROOT, 'data', 'authors', 'michael-soprano.yaml')
begin
  author = YAML.safe_load(File.read(author_path), permitted_classes: [Date, Time], aliases: true) || {}
  %w[title role bio organizations interests education social].each do |field|
    errors << "data/authors/michael-soprano.yaml: missing #{field}" if blank?(author[field])
  end

  social = author['social'].is_a?(Hash) ? author['social'] : {}
  %w[primary academic personal].each do |group|
    profiles = social[group]
    if blank?(profiles)
      errors << "data/authors/michael-soprano.yaml: missing social.#{group}"
      next
    end

    Array(profiles).each_with_index do |profile, index|
      unless profile.is_a?(Hash) && %w[label icon icon_pack link].all? { |field| !blank?(profile[field]) }
        errors << "data/authors/michael-soprano.yaml: social.#{group}[#{index}] requires label, icon, icon_pack, and link"
      end
    end
  end
rescue StandardError => e
  errors << "data/authors/michael-soprano.yaml: #{e.message}"
end

puts "Content checked: #{counts.map { |section, count| "#{count} #{section}" }.join(', ')}"
warnings.each { |warning| warn "WARNING: #{warning}" }

if errors.empty?
  puts "Content validation passed#{warnings.empty? ? '' : " with #{warnings.length} warning(s)"}."
else
  errors.each { |error| warn "ERROR: #{error}" }
  warn "Content validation failed with #{errors.length} error(s)."
  exit 1
end
