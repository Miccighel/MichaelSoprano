#!/usr/bin/env ruby
# frozen_string_literal: true

require 'cgi'
require 'date'
require 'json'
require 'pathname'
require 'time'
require 'uri'
require 'yaml'

SITE_ROOT = File.expand_path('..', __dir__)
PUBLIC_ROOT = File.join(SITE_ROOT, 'public')
PRODUCTION_HOSTS = %w[michaelsoprano.com www.michaelsoprano.com].freeze

SECTIONS = {
  'publications' => {
    public: 'publication',
    archive: 'publication',
    marker: 'legacy-publication-single',
    archive_marker: 'legacy-publication-archive',
    item_marker: 'pub-list-item view-citation'
  },
  'events' => {
    public: 'talk',
    archive: 'event',
    marker: 'legacy-event-single',
    archive_marker: 'legacy-event-archive',
    item_marker: 'media stream-item'
  },
  'blog' => {
    public: 'post',
    archive: 'post',
    marker: 'legacy-blog-single',
    archive_marker: 'legacy-blog-archive',
    item_marker: 'media stream-item'
  }
}.freeze

def load_page(path)
  source = File.binread(path).force_encoding(Encoding::UTF_8)
  match = source.match(/\A---\r?\n(.*?)\r?\n---\r?\n/m)
  raise 'missing YAML front matter' unless match

  data = YAML.safe_load(match[1], permitted_classes: [Date, Time], aliases: true) || {}
  body = source[match.end(0)..].to_s.gsub("\r\n", "\n").rstrip
  [data, body]
end

def normalized(value)
  case value
  when Array
    value.map { |item| normalized(item) }
  when Hash
    value.transform_keys(&:to_s).transform_values { |item| normalized(item) }
  when Date, Time
    value.iso8601
  when String
    value.gsub(/\s+/, ' ').strip
  else
    value
  end
end

def html_text(html)
  CGI.unescapeHTML(
    html
      .gsub(/<script\b.*?<\/script>/mi, ' ')
      .gsub(/<style\b.*?<\/style>/mi, ' ')
      .gsub(/<[^>]+>/, ' ')
  ).gsub(/\s+/, ' ').strip
end

def source_text(source)
  CGI.unescapeHTML(source.to_s)
    .gsub(/!\[([^\]]*)\]\([^)]*\)/, '\\1')
    .gsub(/\[([^\]]+)\]\([^)]*\)/, '\\1')
    .gsub(/<[^>]+>/, ' ')
    .gsub(/[`*_~#>|]/, ' ')
    .gsub(/^\s*[-+]\s+/, ' ')
    .gsub(/\s+/, ' ')
    .strip
end

def significant_excerpt(value, length = 72)
  text = source_text(value)
  return nil if text.length < 20

  text[0, length].strip
end

def attribute_values(markup, names)
  pattern = /(?<![:\w-])(?:#{names.join('|')})\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))/i
  markup.scan(pattern).map { |double_quoted, single_quoted, unquoted| double_quoted || single_quoted || unquoted }
end

def html_url(path)
  relative = Pathname.new(path).relative_path_from(Pathname.new(PUBLIC_ROOT)).to_s
  return '/' if relative == 'index.html'

  relative = relative.delete_suffix('index.html')
  "/#{relative}"
end

def internal_location(raw_reference, source_path)
  reference = CGI.unescapeHTML(raw_reference.to_s.strip)
  return nil if reference.empty? || reference.start_with?('#', 'mailto:', 'tel:', 'javascript:', 'data:')

  reference = "https:#{reference}" if reference.start_with?('//')
  uri = URI.parse(reference)
  return nil if uri.host && !PRODUCTION_HOSTS.include?(uri.host.downcase)

  resolved = if uri.host
               uri
             else
               base = URI("https://michaelsoprano.com#{html_url(source_path)}")
               URI.join(base.to_s, reference)
             end

  decoded_path = URI::DEFAULT_PARSER.unescape(resolved.path.to_s)
  decoded_fragment = URI::DEFAULT_PARSER.unescape(resolved.fragment.to_s)
  [decoded_path.empty? ? '/' : decoded_path, decoded_fragment]
rescue URI::InvalidURIError, ArgumentError
  :invalid
end

def internal_reference(raw_reference, source_path)
  location = internal_location(raw_reference, source_path)
  return location if location.nil? || location == :invalid

  location.first
end

def target_candidates(path)
  clean_path = path.sub(%r{\A/+}, '')
  return [File.join(PUBLIC_ROOT, 'index.html')] if clean_path.empty?

  absolute = File.join(PUBLIC_ROOT, clean_path)
  [absolute, File.join(absolute, 'index.html')]
end

def target_exists?(path)
  target_candidates(path).any? { |candidate| File.file?(candidate) }
end

errors = []
warnings = []

unless Dir.exist?(PUBLIC_ROOT)
  warn "ERROR: #{PUBLIC_ROOT} does not exist; build the site first."
  exit 1
end

html_paths = Dir.glob(File.join(PUBLIC_ROOT, '**', '*.html')).sort
asset_paths = Dir.glob(File.join(PUBLIC_ROOT, '**', '*'), File::FNM_DOTMATCH).select { |path| File.file?(path) }
errors << 'no generated HTML pages found' if html_paths.empty?
errors << 'favicon.ico: missing generated compatibility favicon' unless File.file?(File.join(PUBLIC_ROOT, 'favicon.ico'))

home_path = File.join(PUBLIC_ROOT, 'index.html')
if File.file?(home_path)
  home_html = File.binread(home_path).force_encoding(Encoding::UTF_8)
  favicon_links = home_html.scan(/<link\b[^>]*>/i).select do |link|
    attribute_values(link, %w[rel]).flat_map { |value| value.downcase.split }.include?('icon')
  end
  errors << 'index.html: missing favicon link' if favicon_links.empty?
end

referenced_internal_paths = {}
html_paths.each do |path|
  relative = path.delete_prefix("#{PUBLIC_ROOT}/")
  html = File.binread(path).force_encoding(Encoding::UTF_8)
  text = html_text(html)
  alias_page = html.match?(/<meta\b[^>]*\bhttp-equiv\s*=\s*["']?refresh["']?/i)
  link_markup = html
    .gsub(/<script\b.*?<\/script>/mi, ' ')
    .gsub(/<style\b.*?<\/style>/mi, ' ')

  errors << "#{relative}: missing or empty <title>" unless html.match?(/<title>\s*[^<]+\s*<\/title>/i)
  html_tag = html[/<html\b[^>]*>/i].to_s
  errors << "#{relative}: missing document language" if !alias_page && attribute_values(html_tag, %w[lang]).all?(&:empty?)
  has_viewport = html.scan(/<meta\b[^>]*>/i).any? do |meta|
    attribute_values(meta, %w[name]).any? { |name| name.casecmp('viewport').zero? }
  end
  errors << "#{relative}: missing viewport metadata" if !alias_page && !has_viewport
  errors << "#{relative}: unresolved Hugo template expression" if html.match?(/\{\{[<%\s.]/)
  errors << "#{relative}: page has no readable content" if !alias_page && relative != '404.html' && text.length < 40

  document_ids = attribute_values(html, %w[id])
  duplicate_ids = document_ids.group_by(&:itself).select { |_id, values| values.length > 1 }.keys
  duplicate_ids.each { |id| errors << "#{relative}: duplicate id #{id.inspect}" }

  html.scan(/<img\b[^>]*>/i).each do |image|
    errors << "#{relative}: image is missing an alt attribute" if attribute_values(image, %w[alt]).empty?
  end

  html.scan(/<a\b[^>]*\btarget\s*=\s*["']?_blank["']?[^>]*>/i).each do |anchor|
    rel_values = attribute_values(anchor, %w[rel]).flat_map { |value| value.downcase.split }
    errors << "#{relative}: external-window link is missing rel=noopener" unless rel_values.include?('noopener')
  end

  href_references = attribute_values(link_markup, %w[href])
  references = href_references + attribute_values(link_markup, %w[src poster data-cite-url])
  attribute_values(link_markup, %w[srcset]).each do |srcset|
    srcset.split(',').each { |candidate| references << candidate.strip.split(/\s+/, 2).first }
  end
  link_markup.scan(/\burl\(\s*["']?([^)'"\s]+)["']?\s*\)/i).flatten.each { |url| references << url }

  references.uniq.each do |reference|
    internal_path = internal_reference(reference, path)
    next if internal_path.nil?

    if internal_path == :invalid
      errors << "#{relative}: invalid URL #{reference.inspect}"
      next
    end

    referenced_internal_paths[internal_path] ||= []
    referenced_internal_paths[internal_path] << relative
    next if target_exists?(internal_path)

    errors << "#{relative}: missing internal target #{internal_path.inspect} (from #{reference.inspect})"
  end


  href_references.uniq.each do |reference|
    location = internal_location(reference, path)
    next if location.nil? || location == :invalid

    internal_path, fragment = location
    next if fragment.empty? || fragment.start_with?(':~:text=')

    target = target_candidates(internal_path).find { |candidate| File.file?(candidate) }
    next unless target&.end_with?('.html')

    target_html = File.binread(target).force_encoding(Encoding::UTF_8)
    escaped_fragment = Regexp.escape(fragment)
    next if target_html.match?(/\b(?:id|name)\s*=\s*(?:["']#{escaped_fragment}["']|#{escaped_fragment}(?=[\s>]))/i)

    errors << "#{relative}: missing anchor ##{fragment} in #{internal_path}"
  end
end

Dir.glob(File.join(PUBLIC_ROOT, '**', '*.css')).sort.each do |path|
  relative = path.delete_prefix("#{PUBLIC_ROOT}/")
  css = File.binread(path).force_encoding(Encoding::UTF_8)
  css.scan(/\burl\(\s*["']?([^)'"\s]+)["']?\s*\)/i).flatten.each do |reference|
    internal_path = internal_reference(reference, path)
    next if internal_path.nil?

    if internal_path == :invalid
      errors << "#{relative}: invalid URL #{reference.inspect}"
    elsif !target_exists?(internal_path)
      errors << "#{relative}: missing internal target #{internal_path.inspect} (from #{reference.inspect})"
    end
  end
end

SECTIONS.each do |section, config|
  current_root = File.join(SITE_ROOT, 'content', section)
  current_pages = Dir.glob(File.join(current_root, '*', 'index.md')).sort

  public_section_root = File.join(PUBLIC_ROOT, config[:public])
  rendered_pages = html_paths.select do |path|
    path.start_with?("#{public_section_root}/") && File.binread(path).include?(config[:marker])
  end
  errors << "#{section}: expected #{current_pages.length} rendered detail pages, found #{rendered_pages.length}" unless rendered_pages.length == current_pages.length
  rendered_pages.each do |path|
    next if File.binread(path).match?(/\bdata-pagefind-body\b/)

    errors << "#{path.delete_prefix("#{PUBLIC_ROOT}/")}: detail page is excluded from the search index"
  end

  rendered_titles = rendered_pages.to_h do |path|
    html = File.binread(path).force_encoding(Encoding::UTF_8)
    heading = html[/<h1\b[^>]*>(.*?)<\/h1>/mi, 1].to_s
    [path, html_text(heading)]
  end
  source_title_counts = current_pages.each_with_object(Hash.new(0)) do |source_path, counts|
    data, = load_page(source_path)
    counts[normalized(data['title'])] += 1
  end
  rendered_title_counts = rendered_titles.values.each_with_object(Hash.new(0)) { |title, counts| counts[title] += 1 }
  source_title_counts.each do |title, expected_count|
    rendered_count = rendered_title_counts.fetch(title, 0)
    next if rendered_count == expected_count

    errors << "#{section}: title #{title.inspect} rendered #{rendered_count} time(s), expected #{expected_count}"
  end


  current_pages.each do |source_path|
    data, body = load_page(source_path)
    title = normalized(data['title'])
    candidates = rendered_titles.select { |_path, rendered_title| rendered_title == title }.keys
    expected_excerpts = [
      significant_excerpt(body),
      significant_excerpt(data['abstract']),
      significant_excerpt(data['summary'])
    ]
    if section == 'publications'
      expected_excerpts << significant_excerpt(data.dig('publication', 'name'))
    elsif section == 'events'
      expected_excerpts << significant_excerpt(data['event_name'])
      expected_excerpts << significant_excerpt(data['location'])
    end
    expected_excerpts.compact!
    next if expected_excerpts.empty?

    complete_candidate = candidates.any? do |candidate|
      rendered_html = File.binread(candidate).force_encoding(Encoding::UTF_8)
      rendered_text = html_text(rendered_html)
      rendered_source = CGI.unescapeHTML(rendered_html).gsub(/\s+/, ' ')
      expected_excerpts.all? do |excerpt|
        rendered_text.include?(excerpt) || rendered_source.include?(excerpt)
      end
    end
    next if complete_candidate

    errors << "#{source_path.delete_prefix("#{SITE_ROOT}/")}: substantive content is missing from its rendered detail page"
  end
end

home_html = File.join(PUBLIC_ROOT, 'index.html')
if File.file?(home_html) && !File.binread(home_html).match?(/\bdata-pagefind-body\b/)
  errors << 'index.html: homepage is excluded from the search index'
end

SECTIONS.each do |section, config|
  relative_path = File.join(config[:archive], 'index.html')
  expected_items = Dir.glob(File.join(SITE_ROOT, 'content', section, '*', 'index.md')).length
  path = File.join(PUBLIC_ROOT, relative_path)
  unless File.file?(path)
    errors << "missing archive page #{relative_path}"
    next
  end

  html = File.binread(path).force_encoding(Encoding::UTF_8)
  errors << "#{relative_path}: wrong archive template" unless html.include?(config[:archive_marker])
  rendered_items = html.scan(config[:item_marker]).length
  errors << "#{relative_path}: rendered #{rendered_items} items, expected #{expected_items}" unless rendered_items == expected_items
end

%w[
  media/CVs/Curriculum_Vitae_EN.pdf
  media/CVs/Curriculum_Vitae_IT.pdf
].each do |relative_path|
  absolute_path = File.join(PUBLIC_ROOT, relative_path)
  errors << "missing downloadable file #{relative_path}" unless File.file?(absolute_path) && File.size(absolute_path).positive?
end

pagefind_entry_path = File.join(PUBLIC_ROOT, 'pagefind', 'pagefind-entry.json')
if File.file?(pagefind_entry_path)
  begin
    pagefind_entry = JSON.parse(File.read(pagefind_entry_path))
    indexed_pages = pagefind_entry.fetch('languages', {}).values.sum { |language| language.fetch('page_count', 0).to_i }
    expected_indexed_pages = SECTIONS.keys.sum do |section|
      Dir.glob(File.join(SITE_ROOT, 'content', section, '*', 'index.md')).length
    end + 2 # Homepage and privacy page.
    errors << "search index contains #{indexed_pages} pages, expected #{expected_indexed_pages}" unless indexed_pages == expected_indexed_pages
  rescue JSON::ParserError => e
    errors << "invalid Pagefind index metadata: #{e.message}"
  end
end

errors.uniq!
warnings.uniq!

puts "Generated site audited: #{html_paths.length} HTML pages, #{asset_paths.length} files, #{referenced_internal_paths.length} unique internal targets."
puts "Source content audited: #{SECTIONS.keys.map { |section| "#{Dir.glob(File.join(SITE_ROOT, 'content', section, '*', 'index.md')).length} #{section}" }.join(', ')}."
warnings.each { |warning| warn "WARNING: #{warning}" }

if errors.empty?
  puts "Build audit passed#{warnings.empty? ? '' : " with #{warnings.length} warning(s)"}."
else
  errors.each { |error| warn "ERROR: #{error}" }
  warn "Build audit failed with #{errors.length} error(s)."
  exit 1
end
