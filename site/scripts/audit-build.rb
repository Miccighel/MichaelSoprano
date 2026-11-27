#!/usr/bin/env ruby
# frozen_string_literal: true

require 'cgi'
require 'date'
require 'json'
require 'pathname'
require 'rexml/document'
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
    item_marker: /<article\b[^>]*\bclass=["']?teaching-item\b/i
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
      .gsub(/&(?:rsquo|lsquo);/, "'")
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

def element_attributes(html, element)
  html.scan(/<#{Regexp.escape(element)}\b[^>]*>/i)
end

def metadata_values(html, key)
  element_attributes(html, 'meta').each_with_object([]) do |meta, values|
    names = attribute_values(meta, %w[name property]).map(&:downcase)
    next unless names.include?(key.downcase)

    value = attribute_values(meta, %w[content]).first
    values << value unless value.nil?
  end
end

def links_with_rel(html, rel)
  element_attributes(html, 'link').select do |link|
    attribute_values(link, %w[rel]).flat_map { |value| value.downcase.split }.include?(rel.downcase)
  end
end

def json_ld_documents(html)
  html.scan(/<script\b([^>]*)>(.*?)<\/script>/mi).each_with_object([]) do |(attributes, body), documents|
    types = attribute_values(attributes, %w[type]).map(&:downcase)
    next unless types.include?('application/ld+json')

    documents << JSON.parse(body)
  end
end

def json_ld_types(documents)
  documents.flat_map do |document|
    entries = document.is_a?(Array) ? document : [document]
    entries.each_with_object([]) do |entry, types|
      type = entry.is_a?(Hash) ? entry['@type'] : nil
      types << type unless type.nil?
    end
  end.flatten
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
  errors << 'index.html: missing favicon link' if links_with_rel(home_html, 'icon').empty?
  errors << 'index.html: missing Apple touch icon link' if links_with_rel(home_html, 'apple-touch-icon').empty?
  rss_links = links_with_rel(home_html, 'alternate').select do |link|
    attribute_values(link, %w[type]).any? { |type| type.casecmp('application/rss+xml').zero? }
  end
  errors << 'index.html: missing RSS discovery link' if rss_links.empty?
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

  unless alias_page
    errors << "#{relative}: missing skip-to-content link" unless html.match?(/<a\b[^>]*\bclass=(?:["'][^"']*\bskip-link\b[^"']*["']|skip-link(?=[\s>]))[^>]*\bhref=(?:["']#main-content["']|#main-content(?=[\s>]))/i)
    errors << "#{relative}: missing main content anchor" unless html.match?(/\bid=(?:["']main-content["']|main-content(?=[\s>]))/i)
    canonical_path = html_url(path).sub(%r{/page/\d+/$}, '/')
    expected_canonical = "https://michaelsoprano.com#{canonical_path}"
    canonical_urls = links_with_rel(html, 'canonical').flat_map { |link| attribute_values(link, %w[href]) }
    errors << "#{relative}: canonical URL is #{canonical_urls.inspect}, expected #{expected_canonical.inspect}" unless canonical_urls == [expected_canonical]
    errors << "#{relative}: missing favicon link" if links_with_rel(html, 'icon').empty?
    errors << "#{relative}: missing Apple touch icon link" if links_with_rel(html, 'apple-touch-icon').empty?

    {
      'og:site_name' => 'Michael Soprano',
      'og:url' => expected_canonical,
      'twitter:site' => '@Miccighel_',
      'twitter:creator' => '@Miccighel_'
    }.each do |key, expected|
      values = metadata_values(html, key)
      errors << "#{relative}: #{key} metadata is #{values.inspect}, expected #{expected.inspect}" unless values == [expected]
    end
    %w[og:title og:description twitter:card].each do |key|
      values = metadata_values(html, key)
      errors << "#{relative}: missing or empty #{key} metadata" if values.empty? || values.any?(&:empty?)
    end

    begin
      json_ld = json_ld_documents(html)
      errors << "#{relative}: missing JSON-LD structured data" if json_ld.empty?
      if JSON.generate(json_ld).match?(/"(?:url|image)":null/)
        errors << "#{relative}: JSON-LD contains a null URL or image"
      end
    rescue JSON::ParserError => e
      errors << "#{relative}: invalid JSON-LD structured data (#{e.message})"
    end
  end

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

  %w[og:image twitter:image].flat_map { |key| metadata_values(html, key) }.uniq.each do |reference|
    internal_path = internal_reference(reference, path)
    next if internal_path.nil?

    if internal_path == :invalid
      errors << "#{relative}: invalid social preview image URL #{reference.inspect}"
    elsif !target_exists?(internal_path)
      errors << "#{relative}: missing social preview image #{internal_path.inspect}"
    end
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
    html = File.binread(path).force_encoding(Encoding::UTF_8)
    if section == 'publications' && element_attributes(html, 'main').length != 1
      errors << "#{path.delete_prefix("#{PUBLIC_ROOT}/")}: publication detail must expose exactly one main landmark"
    end
    unless html.match?(/\bdata-pagefind-body\b/)
      errors << "#{path.delete_prefix("#{PUBLIC_ROOT}/")}: detail page is excluded from the search index"
    end

    begin
      expected_json_ld_type = { 'publications' => 'Article', 'events' => 'Event', 'blog' => 'BlogPosting' }.fetch(section)
      types = json_ld_types(json_ld_documents(html))
      unless types.include?(expected_json_ld_type)
        errors << "#{path.delete_prefix("#{PUBLIC_ROOT}/")}: JSON-LD types #{types.inspect} do not include #{expected_json_ld_type.inspect}"
      end
    rescue JSON::ParserError
      # The general per-page check reports the malformed document.
    end
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
    expected_dates = case section
                     when 'publications'
                       { 'datePublished' => normalized(data.fetch('date'))[0, 10] }
                     when 'events'
                       dates = {
                         'startDate' => normalized(data.fetch('event_start')),
                         'endDate' => normalized(data.fetch('event_end'))
                       }
                       data['event_all_day'] || data['event_time_unknown'] ? dates.transform_values { |value| value[0, 10] } : dates
                     end
    if expected_dates
      schema_type = section == 'publications' ? 'Article' : 'Event'
      matches_dates = candidates.any? do |candidate|
        rendered_html = File.binread(candidate).force_encoding(Encoding::UTF_8)
        json_ld_documents(rendered_html).any? do |document|
          next false unless document.is_a?(Hash) && document['@type'] == schema_type
          next false unless document.slice(*expected_dates.keys) == expected_dates

          section != 'publications' ||
            metadata_values(rendered_html, 'article:published_time').map { |value| value[0, 10] } == [expected_dates['datePublished']]
        end
      rescue JSON::ParserError
        false # Already reported by the general JSON-LD check.
      end
      unless matches_dates
        errors << "#{source_path.delete_prefix("#{SITE_ROOT}/")}: rendered #{schema_type} dates must match #{expected_dates.inspect}"
      end
    end

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
      rendered_source = CGI.unescapeHTML(rendered_html.gsub(/&(?:rsquo|lsquo);/, "'")).gsub(/\s+/, ' ')
      expected_excerpts.all? do |excerpt|
        rendered_text.include?(excerpt) || rendered_source.include?(excerpt)
      end
    end
    next if complete_candidate

    errors << "#{source_path.delete_prefix("#{SITE_ROOT}/")}: substantive content is missing from its rendered detail page"
  end
end

association_sections = {}
html_paths.select { |path| html_url(path).match?(%r{\A/(?:publication|talk)/[^/]+/\z}) }.each do |path|
  html = File.read(path)
  associated = html[/<section\b[^>]*\baria-labelledby=["']?associated-materials-heading\b[^>]*>.*?<\/section>/mi]
  next unless associated

  source_url = html_url(path)
  related = html[/<section\b[^>]*\baria-labelledby=["']?related-heading\b[^>]*>.*?<\/section>/mi].to_s
  links = element_attributes(associated, 'a')
  targets = links.flat_map { |link| attribute_values(link, %w[href]) }.grep(%r{\A/(?:publication|talk)/})
  repeated = targets & attribute_values(related, %w[href])
  errors << "#{source_url}: related list repeats associated pages #{repeated.join(', ')}" unless repeated.empty?
  errors << "#{source_url}: duplicate associated page" unless targets.uniq == targets
  association_sections[source_url] = targets

  event_labels = links.flat_map { |link| attribute_values(link, %w[aria-label]) }.grep(/\AEvent details:/)
  errors << "#{source_url}: event detail links are indistinguishable" unless event_labels.uniq == event_labels
end
association_sections.each do |source_url, targets|
  targets.each do |target|
    errors << "#{source_url}: association to #{target} is not reciprocal" unless association_sections.fetch(target, []).include?(source_url)
  end
end
expected_associations = YAML.safe_load_file(File.join(SITE_ROOT, 'data', 'presentation_publications.yaml')).length
errors << 'presentation/publication links do not match the confirmed pair count' unless association_sections.values.sum(&:length) == expected_associations * 2

home_html = File.join(PUBLIC_ROOT, 'index.html')
if File.file?(home_html) && !File.binread(home_html).match?(/\bdata-pagefind-body\b/)
  errors << 'index.html: homepage is excluded from the search index'
end

render_link_path = File.join(SITE_ROOT, 'layouts', '_markup', 'render-link.html')
unless File.file?(render_link_path)
  errors << 'missing local Markdown link render hook'
end
%w[go.mod go.sum hugoblox.yaml config/_default/module.yaml].each do |relative_path|
  errors << "legacy Hugo module file is still present: #{relative_path}" if File.exist?(File.join(SITE_ROOT, relative_path))
end
params_path = File.join(SITE_ROOT, 'config', '_default', 'params.yaml')
if File.file?(params_path) && File.read(params_path).match?(/^hugoblox:/)
  errors << 'config/_default/params.yaml: legacy hugoblox namespace is still present'
end
custom_css_path = File.join(SITE_ROOT, 'assets', 'css', 'custom.css')
if File.file?(custom_css_path)
  custom_css = File.read(custom_css_path)
  mobile_brand_anchored = custom_css.scan(/#site-header \.legacy-navbar-brand-mobile\s*\{[^}]+\}/).any? do |rule|
    rule.include?('position: absolute') && rule.include?('top: 0') && rule.include?('height: 50px')
  end
  unless mobile_brand_anchored
    errors << 'assets/css/custom.css: mobile navbar brand is not anchored to the header'
  end
end
%w[
  i18n/en.yaml
  layouts/_partials/css.html
  layouts/_partials/tailwind_sources.html
  assets/css/main.css
  assets/css/design-system.css
  assets/css/config/tailwind.css
  assets/css/config/theme.css
  assets/js/hb-nav.js
  assets/js/homepage-nav.js
  assets/js/publication-filters.js
  assets/js/site-citations.js
  scripts/build-site.rb
].each do |relative_path|
  errors << "missing local support file #{relative_path}" unless File.file?(File.join(SITE_ROOT, relative_path))
end

Dir.glob(File.join(SITE_ROOT, 'layouts', '**', '*.html')).sort.each do |layout_path|
  source = File.binread(layout_path).force_encoding(Encoding::UTF_8)
  source.scan(/<script\b([^>]*)>/mi).each do |attributes|
    markup = attributes.first.to_s
    next if markup.match?(/\bsrc\s*=/i) || markup.match?(/\btype\s*=\s*["']application\/ld\+json["']/i)

    errors << "#{layout_path.delete_prefix("#{SITE_ROOT}/")}: executable JavaScript must be stored in assets/js"
  end
end
if File.file?(home_html)
  rendered_home = File.binread(home_html).force_encoding(Encoding::UTF_8)
  unless rendered_home.match?(/<a\b[^>]*href=["']https:\/\/scholar\.google\.com\/[^"']*["'][^>]*target=(?:["']_blank["']|_blank\b)[^>]*rel=(?:["']noopener["']|noopener\b)/i)
    errors << 'index.html: external Markdown links do not use the local safe-link behavior'
  end
  errors << 'index.html: search attribution is not Pagefind' unless rendered_home.include?('Search by Pagefind')
  errors << 'index.html: whitespace before punctuation after a link' if rendered_home.match?(%r{</a>\s+[.,;:](?=\s|<|\z)}i)

  home_data = YAML.safe_load(File.read(File.join(SITE_ROOT, 'data', 'home.yaml')), aliases: true)
  { 'publications' => 'publications', 'presentations' => 'events' }.each do |section_id, content_section|
    limit = home_data.dig(section_id, 'homepage_limit') || 15
    available = Dir.glob(File.join(SITE_ROOT, 'content', content_section, '*', 'index.md')).length
    expected = [limit, available].min
    section_html = rendered_home[/<section\b[^>]*\bid=(?:["']#{section_id}["']|#{section_id}(?=[\s>]))[^>]*>(.*?)<\/section>/mi, 1].to_s
    actual = section_html.scan(/<article\b/i).length
    errors << "index.html: #{section_id} renders #{actual} items, expected #{expected}" unless actual == expected
  end
end

privacy_source_path = File.join(SITE_ROOT, 'content', 'privacy.md')
privacy_path = File.join(PUBLIC_ROOT, 'privacy', 'index.html')
if File.file?(privacy_source_path) && File.file?(privacy_path)
  privacy_data, privacy_body = load_page(privacy_source_path)
  privacy_html = File.binread(privacy_path).force_encoding(Encoding::UTF_8)
  privacy_text = html_text(privacy_html)
  privacy_heading = html_text(privacy_html[/<h1\b[^>]*>.*?<\/h1>/mi].to_s)

  errors << 'privacy/index.html: wrong local template' unless privacy_html.match?(/\bdata-local-layout=["']?privacy\b/i)
  %w[sidebar toc page-sharer].each do |component|
    if privacy_html.match?(/\bdata-local-component=["']?#{Regexp.escape(component)}\b/i)
      errors << "privacy/index.html: obsolete #{component} component is still rendered"
    end
  end
  errors << 'privacy/index.html: wrong heading' unless privacy_heading == normalized(privacy_data['title'])
  errors << 'privacy/index.html: whitespace before punctuation after a link' if privacy_html.match?(%r{</a>\s+[.,;:](?=\s|<|\z)}i)
  errors << 'privacy/index.html: page is excluded from the search index' unless privacy_html.match?(/\bdata-pagefind-body\b/)
  significant_excerpt(privacy_body)&.then do |excerpt|
    errors << 'privacy/index.html: substantive content is missing' unless privacy_text.include?(excerpt)
  end

  errors << 'privacy/index.html: missing last-updated timestamp' unless privacy_html.match?(/<time\b[^>]*>.*?Last updated on.*?<\/time>/mi)
else
  errors << 'missing privacy source or generated page'
end

if File.file?(home_path)
  home_source = File.binread(home_path).force_encoding(Encoding::UTF_8)
  map_frame = home_source.scan(/<iframe\b[^>]*>/i).find { |tag| attribute_values(tag, %w[src]).any? { |src| src.start_with?('https://www.google.com/maps?') } }.to_s
  errors << 'index.html: missing lazily loaded, labelled Google Map' unless attribute_values(map_frame, %w[loading]) == ['lazy'] && attribute_values(map_frame, %w[title]).any? { |title| !title.empty? }
  errors << 'index.html: missing Google Maps directions link' unless home_source.include?('https://www.google.com/maps/dir/?')
end
if File.file?(privacy_path)
  privacy_source = File.binread(privacy_path).force_encoding(Encoding::UTF_8)
  errors << 'privacy/index.html: embedded map must be limited to the homepage' if privacy_source.match?(/<iframe\b[^>]*google\.com\/maps/i)
end

source_tags = Dir.glob(File.join(SITE_ROOT, 'content', '**', '*.md')).flat_map do |source_path|
  data, = load_page(source_path)
  Array(data['tags'])
end

{
  'authors' => ['Authors', 59],
  'categories' => ['Categories', 1],
  'publication_types' => ['Publication types', 3],
  'tags' => ['All topics', source_tags.uniq.length]
}.each do |taxonomy, (expected_title, expected_terms)|
  relative_path = File.join(taxonomy, 'index.html')
  path = File.join(PUBLIC_ROOT, relative_path)
  unless File.file?(path)
    errors << "missing taxonomy index #{relative_path}"
    next
  end

  html = File.binread(path).force_encoding(Encoding::UTF_8)
  heading = html_text(html[/<h1\b[^>]*>.*?<\/h1>/mi].to_s)
  term_links = if taxonomy == 'tags'
                 html.scan(/<a\b[^>]*\bhref=["']?\/tag\//i)
               else
                 html.scan(/<a\b[^>]*class=["'][^"']*\binline-flex\b[^"']*["'][^>]*>/mi)
               end
  errors << "#{relative_path}: wrong local template" unless html.match?(/\bdata-local-layout=["']?taxonomy-index\b/i)
  errors << "#{relative_path}: wrong heading #{heading.inspect}" unless heading == expected_title
  errors << "#{relative_path}: missing Pagefind exclusion" unless html.match?(/\bdata-pagefind-ignore\b/)
  errors << "#{relative_path}: rendered #{term_links.length} terms, expected #{expected_terms}" unless term_links.length == expected_terms
end

tags_index_path = File.join(PUBLIC_ROOT, 'tags', 'index.html')
if File.file?(tags_index_path)
  tags_index_html = File.binread(tags_index_path).force_encoding(Encoding::UTF_8)
  title = html_text(tags_index_html[/<title>.*?<\/title>/mi].to_s)
  errors << "tags/index.html: unexpected browser title #{title.inspect}" unless title == 'All topics | Michael Soprano'
  {
    '/tag/amazon-mechanical-turk/' => 'Amazon Mechanical Turk 2',
    '/tag/artificial-intelligence/' => 'Artificial Intelligence 3',
    '/tag/cognitive-biases/' => 'Cognitive Biases 2',
    '/tag/conversational-agents/' => 'Conversational Agents 3',
    '/tag/covid-19/' => 'COVID-19 3',
    '/tag/crowd_frame/' => 'Crowd_Frame 2',
    '/tag/crowdsourcing/' => 'Crowdsourcing 24',
    '/tag/dom-manipulation/' => 'DOM Manipulation 1',
    '/tag/hits/' => 'HITS 3',
    '/tag/network-analysis/' => 'Network Analysis 3',
    '/tag/prisma-2020/' => 'PRISMA 2020 2',
    '/tag/prolific/' => 'Prolific 2',
    '/tag/systematic-reviews/' => 'Systematic Reviews 3',
    '/tag/test-collections/' => 'Test Collections 3',
    '/tag/trec/' => 'TREC 1',
    '/tag/toloka/' => 'Toloka 2'
  }.each do |href, expected_text|
    anchor = tags_index_html[/<a\b[^>]*\bhref\s*=\s*(?:["']#{Regexp.escape(href)}["']|#{Regexp.escape(href)}(?=[\s>]))[^>]*>.*?<\/a>/mi]
    rendered_text = html_text(anchor.to_s)
    errors << "tags/index.html: #{href} is labelled #{rendered_text.inspect}, expected #{expected_text.inspect}" unless rendered_text == expected_text
  end
end

topic_alias_paths = Dir.glob(File.join(SITE_ROOT, 'content', 'tags', '*', '_index.md')).flat_map do |path|
  data, = load_page(path)
  target = "/tag/#{File.basename(File.dirname(path))}/"
  Array(data['aliases']).map do |alias_url|
    relative = File.join(alias_url.delete_prefix('/'), 'index.html')
    redirect_path = File.join(PUBLIC_ROOT, relative)
    if File.file?(redirect_path)
      html = File.read(redirect_path)
      refresh = element_attributes(html, 'meta').find { |meta| attribute_values(meta, %w[http-equiv]).include?('refresh') }
      unless refresh && attribute_values(refresh, %w[content]) == ["0; url=#{target}"]
        errors << "#{relative}: missing redirect to #{target}"
      end
      canonical = links_with_rel(html, 'canonical').flat_map { |link| attribute_values(link, %w[href]) }
      errors << "#{relative}: wrong redirect canonical URL" unless canonical == ["https://michaelsoprano.com#{target}"]
    else
      errors << "#{relative}: missing topic redirect"
    end
    relative
  end
end

term_roots = %w[tag category publication-type]
term_layout_paths = html_paths.select do |path|
  relative = path.delete_prefix("#{PUBLIC_ROOT}/")
  next false unless term_roots.any? { |root| relative.start_with?("#{root}/") }
  next false if relative.match?(%r{/page/1/index\.html\z})
  next false if topic_alias_paths.include?(relative)

  true
end
missing_local_term_layout = term_layout_paths.reject do |path|
  relative = path.delete_prefix("#{PUBLIC_ROOT}/")
  expected_layout = relative.start_with?('tag/') ? 'tag-term' : 'term-list'
  File.binread(path).match?(/\bdata-local-layout=["']?#{Regexp.escape(expected_layout)}\b/i)
end
missing_local_term_layout.each do |path|
  errors << "#{path.delete_prefix("#{PUBLIC_ROOT}/")}: wrong term-list template"
end

source_tag_assignments = source_tags.length
topic_term_paths = term_layout_paths.select { |path| path.delete_prefix("#{PUBLIC_ROOT}/").start_with?('tag/') }
rendered_tag_results = topic_term_paths.sum do |path|
  html = File.read(path)
  relative = path.delete_prefix("#{PUBLIC_ROOT}/")
  index_roots = html.scan(/<[^>]+\bdata-pagefind-body\b[^>]*>/i)
  unless index_roots.length == 1 && index_roots.first.match?(/\A<h1\b/i) &&
         index_roots.first.include?('kind:Topic') && index_roots.first.include?('topicTitle[data-topic-key]')
    errors << "#{relative}: search must index only the topic heading, with Topic metadata and an exact title filter"
  end
  sections = element_attributes(html, 'section').flat_map { |section| attribute_values(section, %w[id]) }
  has_teaching = sections.include?('topic-teaching')
  has_research = sections.intersect?(%w[topic-publications topic-presentations])
  expected_area = if has_teaching && has_research
                    'Research & Teaching topic'
                  elsif has_teaching
                    'Teaching topic'
                  else
                    'Research topic'
                  end
  eyebrow = html[/<p\b[^>]*\bclass=["']?topic-archive-eyebrow\b[^>]*>.*?<\/p>/mi].to_s
  errors << "#{path.delete_prefix("#{PUBLIC_ROOT}/")}: expected #{expected_area.inspect}" unless html_text(eyebrow) == expected_area
  html.scan(/\bdata-topic-result\b/i).length
end
unless rendered_tag_results == source_tag_assignments
  errors << "tag pages render #{rendered_tag_results} results, expected #{source_tag_assignments} source assignments"
end

source_term_assignments = Dir.glob(File.join(SITE_ROOT, 'content', '**', '*.md')).sum do |source_path|
  data, = load_page(source_path)
  %w[categories publication_types].sum { |field| Array(data[field]).length }
end
secondary_term_paths = term_layout_paths.reject { |path| path.delete_prefix("#{PUBLIC_ROOT}/").start_with?('tag/') }
rendered_term_rows = secondary_term_paths.sum do |path|
  File.binread(path).scan(/<article\b[^>]*\bdata-archive-result\b/i).length
end
unless rendered_term_rows == source_term_assignments
  errors << "term lists render #{rendered_term_rows} rows, expected #{source_term_assignments} source assignments"
end

author_layout_paths = html_paths.select do |path|
  relative = path.delete_prefix("#{PUBLIC_ROOT}/")
  next false unless relative.start_with?('authors/')
  next false if relative == 'authors/index.html' || relative.match?(%r{/page/1/index\.html\z})

  true
end
missing_local_author_layout = author_layout_paths.reject do |path|
  File.binread(path).match?(/\bdata-local-layout=["']?author-term\b/i)
end
missing_local_author_layout.each do |path|
  errors << "#{path.delete_prefix("#{PUBLIC_ROOT}/")}: wrong author-term template"
end

source_author_assignments = Dir.glob(File.join(SITE_ROOT, 'content', '**', '*.md')).sum do |source_path|
  data, = load_page(source_path)
  Array(data['authors']).length
end
rendered_author_rows = author_layout_paths.sum do |path|
  File.binread(path).scan(/<article\b[^>]*\bdata-archive-result\b/i).length
end
unless rendered_author_rows == source_author_assignments
  errors << "author lists render #{rendered_author_rows} rows, expected #{source_author_assignments} source assignments"
end

(secondary_term_paths + author_layout_paths).group_by { |path| path.sub(%r{(?:/page/\d+)?/index\.html\z}, '') }.each do |archive, paths|
  urls = paths.flat_map do |path|
    html = File.binread(path)
    html.scan(/<article\b[^>]*\bdata-archive-result\b[^>]*>(.*?)<\/article>/mi).flatten.map do |row|
      errors << "#{path}: unexpected image in text row" if row.match?(/<img\b/i)
      url = row[/<h2>\s*<a\b[^>]*\bhref=["']?([^\s"'>]+)/i, 1]
      errors << "#{path}: missing row title link" unless url
      url
    end
  end
  errors << "#{archive}: duplicate results across pages" unless urls.uniq.length == urls.length
end
local_responsive_images = html_paths.sum do |path|
  File.binread(path).scan(/\bdata-responsive-image-provider=(?:["']local["']|local(?=[\s>]))/i).length
end
errors << 'local responsive-image processor is not represented in generated HTML' if local_responsive_images.zero?

source_event_card_assignments = Dir.glob(File.join(SITE_ROOT, 'content', 'events', '*', 'index.md')).sum do |source_path|
  data, = load_page(source_path)
  %w[authors categories publication_types].sum { |field| Array(data[field]).length }
end
local_event_dates = html_paths.sum do |path|
  File.binread(path).scan(/\bdata-event-date-provider=(?:["']local["']|local(?=[\s>]))/i).length
end
unless local_event_dates == source_event_card_assignments
  errors << "local event-date formatter marks #{local_event_dates} of #{source_event_card_assignments} event cards"
end

local_icons = html_paths.sum do |path|
  File.binread(path).scan(/\bdata-icon-provider=(?:["']local["']|local(?=[\s>]))/i).length
end
local_catalog_icons = html_paths.sum do |path|
  File.binread(path).scan(/\bdata-icon-catalog=(?:["']local["']|local(?=[\s>]))/i).length
end
unless local_catalog_icons == local_icons
  errors << "local icon catalog supplies #{local_catalog_icons} of #{local_icons} rendered resolver icons"
end

expected_author_profile_resolutions = author_layout_paths.length
local_author_profile_resolutions = html_paths.sum do |path|
  File.binread(path).scan(/\bdata-author-profile-provider=(?:["']local["']|local(?=[\s>]))/i).length
end
unless local_author_profile_resolutions == expected_author_profile_resolutions
  errors << "local author resolver marks #{local_author_profile_resolutions} of #{expected_author_profile_resolutions} profile resolutions"
end

paginated_paths = html_paths.select do |path|
  File.binread(path).match?(/<a\b[^>]*\bclass=["']?page-link\b/i)
end
missing_local_paginator = paginated_paths.reject do |path|
  File.binread(path).match?(/\bdata-local-component=["']?paginator\b/i)
end
missing_local_paginator.each do |path|
  errors << "#{path.delete_prefix("#{PUBLIC_ROOT}/")}: wrong paginator component"
end

not_found_path = File.join(PUBLIC_ROOT, '404.html')
if File.file?(not_found_path)
  not_found_html = File.read(not_found_path)
  errors << '404.html: wrong heading' unless html_text(not_found_html[/<h1\b[^>]*>.*?<\/h1>/mi].to_s) == 'Page not found'
  errors << '404.html: missing Pagefind exclusion' unless not_found_html.match?(/\bdata-pagefind-ignore\b/)
  recommendations = not_found_html.scan(/<li>\s*<a\b([^>]*)>(.*?)<\/a>\s*<\/li>/mi)
  expected_recommendations = {
    'Publications' => '/#publications',
    'Presentations' => '/#presentations',
    'Teaching' => '/#teaching',
    'Topics' => '/#tags',
    'Contact' => '/#contact'
  }
  actual_recommendations = recommendations.to_h do |attributes, label|
    [html_text(label), attribute_values(attributes, %w[href]).first]
  end
  errors << '404.html: incorrect site recommendations' unless actual_recommendations == expected_recommendations
end

SECTIONS.each do |section, config|
  relative_path = File.join(config[:archive], 'index.html')
  source_paths = Dir.glob(File.join(SITE_ROOT, 'content', section, '*', 'index.md'))
  expected_items = source_paths.count do |source_path|
    section != 'blog' || load_page(source_path).first['course_hidden'] != true
  end
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

publication_sources = Dir.glob(File.join(SITE_ROOT, 'content', 'publications', '*', 'index.md')).sort
doi_sources = publication_sources.each_with_object([]) do |source_path, entries|
  source_data, = load_page(source_path)
  doi = source_data.dig('identifiers', 'doi')
  entries << [source_path, doi.to_s] if doi
end
doi_sources.each do |source_path, doi|
  slug = File.basename(File.dirname(source_path))
  generated_path = File.join(PUBLIC_ROOT, 'publication', slug, 'index.html')
  generated_html = File.file?(generated_path) ? File.binread(generated_path).force_encoding(Encoding::UTF_8) : ''
  escaped_doi = Regexp.escape("https://doi.org/#{doi}")
  unless generated_html.match?(/<a\b[^>]*href=["']?#{escaped_doi}["'\s>][^>]*>DOI<\/a>/i)
    errors << "publication/#{slug}/index.html: missing DOI button for #{doi}"
  end
end
errors << "publication DOI inventory contains #{doi_sources.length} entries, expected 30" unless doi_sources.length == 30

%w[
  media/CVs/Curriculum_Vitae_EN.pdf
  media/CVs/Curriculum_Vitae_IT.pdf
].each do |relative_path|
  absolute_path = File.join(PUBLIC_ROOT, relative_path)
  errors << "missing downloadable file #{relative_path}" unless File.file?(absolute_path) && File.size(absolute_path).positive?
end

standalone_page_count = Dir.glob(File.join(SITE_ROOT, 'content', '*.md')).count do |path|
  File.basename(path) != '_index.md'
end

rss_path = File.join(PUBLIC_ROOT, 'index.xml')
if File.file?(rss_path)
  begin
    rss = REXML::Document.new(File.read(rss_path))
    rss_title = rss.elements['rss/channel/title']&.text.to_s.strip
    rss_items = rss.get_elements('rss/channel/item')
    errors << 'index.xml: RSS channel title is missing' if rss_title.empty?
    expected_rss_items = SECTIONS.keys.sum { |section| Dir.glob(File.join(SITE_ROOT, 'content', section, '*', 'index.md')).length } + standalone_page_count
    errors << "index.xml: RSS contains #{rss_items.length} items, expected #{expected_rss_items}" unless rss_items.length == expected_rss_items
    errors << 'index.xml: legacy HugoBlox generator is still present' if File.read(rss_path).include?('HugoBlox')
  rescue REXML::ParseException => e
    errors << "index.xml: invalid RSS XML (#{e.message})"
  end
else
  errors << 'missing root RSS feed index.xml'
end

sitemap_path = File.join(PUBLIC_ROOT, 'sitemap.xml')
if File.file?(sitemap_path)
  begin
    sitemap_source = File.read(sitemap_path)
    REXML::Document.new(sitemap_source)
    sitemap_urls = sitemap_source.scan(/<url>/).length
    expected_sitemap_urls = 128 + source_tags.uniq.length + standalone_page_count + Dir.glob(File.join(SITE_ROOT, 'content', 'blog', '*', 'index.md')).length
    errors << "sitemap.xml: contains #{sitemap_urls} URLs, expected #{expected_sitemap_urls}" unless sitemap_urls == expected_sitemap_urls
  rescue REXML::ParseException => e
    errors << "sitemap.xml: invalid XML (#{e.message})"
  end
else
  errors << 'missing sitemap.xml'
end

robots_path = File.join(PUBLIC_ROOT, 'robots.txt')
if File.file?(robots_path)
  robots = File.read(robots_path)
  errors << 'robots.txt: missing production sitemap URL' unless robots.include?('Sitemap: https://michaelsoprano.com/sitemap.xml')
else
  errors << 'missing robots.txt'
end

pagefind_entry_path = File.join(PUBLIC_ROOT, 'pagefind', 'pagefind-entry.json')
if File.file?(pagefind_entry_path)
  begin
    pagefind_entry = JSON.parse(File.read(pagefind_entry_path))
    indexed_pages = pagefind_entry.fetch('languages', {}).values.sum { |language| language.fetch('page_count', 0).to_i }
    expected_indexed_pages = SECTIONS.keys.sum do |section|
      Dir.glob(File.join(SITE_ROOT, 'content', section, '*', 'index.md')).length
    end + 1 + standalone_page_count + topic_term_paths.length
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
