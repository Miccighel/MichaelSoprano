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

    if section == 'publications'
      Array(data['publication_types']).each do |publication_type|
        next if PUBLICATION_TYPES.include?(publication_type)

        errors << "#{relative_path}: unsupported publication type #{publication_type.inspect}"
      end
      publication_name = data.dig('publication', 'name') if data['publication'].is_a?(Hash)
      errors << "#{relative_path}: missing publication.name" if blank?(publication_name)
    end

    if section == 'events' && data['event_start'] && data['event_end']
      begin
        start_time = Time.parse(data['event_start'].to_s)
        end_time = Time.parse(data['event_end'].to_s)
        errors << "#{relative_path}: event_end precedes event_start" if end_time < start_time
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
  %w[author visits experience].each do |field|
    errors << "data/home.yaml: missing #{field}" if blank?(home[field])
  end
rescue StandardError => e
  errors << "data/home.yaml: #{e.message}"
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
