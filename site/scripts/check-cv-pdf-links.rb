#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'uri'

module CvPdfLinks
  SITE_ROOT = File.expand_path('..', __dir__)
  PUBLIC_ROOT = File.join(SITE_ROOT, 'public')
  CV_NAMES = %w[Curriculum_Vitae_EN.pdf Curriculum_Vitae_IT.pdf].freeze
  HOSTS = %w[michaelsoprano.com www.michaelsoprano.com].freeze

  def self.annotations(output)
    output.lines.map do |line|
      page, _type, url = line.strip.split(/\s+/, 3)
      [page.to_i, url] if page&.match?(/\A\d+\z/) && url
    end.compact
  end

  def self.local_path(url)
    uri = URI.parse(url)
    return unless %w[http https].include?(uri.scheme&.downcase) && HOSTS.include?(uri.host&.downcase)

    path = URI::DEFAULT_PARSER.unescape(uri.path)
    segments = path.split('/').reject(&:empty?)
    return [] if segments.any? { |segment| segment == '.' || segment == '..' || segment.include?("\0") }

    segments << 'index.html' if path.end_with?('/')
    segments
  rescue URI::InvalidURIError
    nil
  end

  # Compare each component explicitly: a case-insensitive local filesystem must
  # still catch URLs that would 404 on case-sensitive GitHub Pages.
  def self.exact_file?(root, segments)
    current = root
    segments.each do |segment|
      return false unless File.directory?(current) && Dir.children(current).include?(segment)

      current = File.join(current, segment)
    end
    File.file?(current)
  end

  def self.missing_links(output, public_root)
    annotations(output).map do |page, url|
      segments = local_path(url)
      next unless segments
      next if exact_file?(public_root, segments)

      [page, url]
    end.compact.uniq
  end

  def self.check(public_root = PUBLIC_ROOT)
    errors = []
    checked = 0
    CV_NAMES.each do |name|
      pdf = File.join(public_root, 'media', 'CVs', name)
      unless File.file?(pdf)
        errors << "#{name}: missing PDF"
        next
      end

      output, stderr, status = Open3.capture3('pdfinfo', '-url', pdf)
      unless status.success?
        errors << "#{name}: pdfinfo failed: #{stderr.strip}"
        next
      end

      links = annotations(output)
      if links.empty?
        errors << "#{name}: no PDF link annotations found"
        next
      end

      checked += links.count { |_page, url| local_path(url) }
      missing_links(output, public_root).each do |page, url|
        errors << "#{name}, page #{page}: missing site target for #{url}"
      end
    end

    if errors.empty?
      puts "CV PDF links checked: #{checked} site-hosted annotations across #{CV_NAMES.length} PDFs."
      true
    else
      errors.each { |error| warn "ERROR: #{error}" }
      false
    end
  rescue Errno::ENOENT
    warn 'ERROR: pdfinfo is required to check CV PDF links (install Poppler).'
    false
  end
end

exit(CvPdfLinks.check ? 0 : 1) if $PROGRAM_NAME == __FILE__
