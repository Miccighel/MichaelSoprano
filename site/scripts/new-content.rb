#!/usr/bin/env ruby
# frozen_string_literal: true

require 'date'
require 'fileutils'

ROOT = File.expand_path('..', __dir__)
TYPE_TO_SECTION = {
  'publication' => 'publications',
  'event' => 'events',
  'teaching' => 'blog'
}.freeze

def usage
  <<~TEXT
    Usage: ./scripts/new-content.rb TYPE SLUG

    TYPE can be publication, event, or teaching.
    SLUG must contain lowercase letters, numbers, and hyphens only.

    Examples:
      ./scripts/new-content.rb publication my-new-paper
      ./scripts/new-content.rb event conference-name-2027
      ./scripts/new-content.rb teaching new-course
  TEXT
end

type, slug = ARGV
if %w[-h --help].include?(type)
  puts usage
  exit
end

unless TYPE_TO_SECTION.key?(type) && slug&.match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)
  warn usage
  exit 2
end

section = TYPE_TO_SECTION.fetch(type)
target_dir = File.join(ROOT, 'content', section, slug)
target = File.join(target_dir, 'index.md')
abort "ERROR: content already exists: #{target}" if File.exist?(target)

today = Date.today.iso8601
title = slug.split('-').map(&:capitalize).join(' ')

front_matter = case type
               when 'publication'
                 <<~YAML
                   ---
                   title: "#{title}"
                   subtitle: ""
                   summary: ""
                   authors:
                     - Michael Soprano
                   tags: []
                   categories: []
                   date: "#{today}"
                   lastmod: "#{today}"
                   draft: true
                   featured: false
                   publication_types:
                     - paper-conference
                   abstract: ""
                   publication:
                     name: ""
                   identifiers:
                     doi:
                   links: []
                   ---

                 YAML
               when 'event'
                 <<~YAML
                   ---
                   title: "#{title}"
                   subtitle: ""
                   summary: ""
                   authors:
                     - Michael Soprano
                   tags: []
                   categories: []
                   event_name: ""
                   event_url: ""
                   location: ""
                   event_start: "#{today}T09:00:00"
                   event_end: "#{today}T10:00:00"
                   event_all_day: false
                   date: "#{today}T09:00:00"
                   draft: true
                   featured: false
                   links: []
                   ---

                 YAML
               when 'teaching'
                 <<~YAML
                   ---
                   title: "#{title}"
                   subtitle: ""
                   summary: ""
                   authors:
                     - admin
                   tags:
                     - Teaching
                   categories:
                     - teaching
                   date: "#{today}T09:00:00Z"
                   lastmod: "#{today}T09:00:00Z"
                   draft: true
                   featured: false
                   image:
                     caption: ""
                     focal_point: ""
                     preview_only: false
                   ---

                   # Aims

                   Describe the course aims here.
                 YAML
               end

FileUtils.mkdir_p(target_dir)
File.write(target, front_matter)

puts "Created: #{target}"
puts 'The new content is a draft. Complete the front matter, add any bundle assets,'
puts 'set draft to false, and run ./scripts/check-content.rb before building.'
