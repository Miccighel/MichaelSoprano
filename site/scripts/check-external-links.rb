#!/usr/bin/env ruby
# frozen_string_literal: true

require 'cgi'
require 'net/http'
require 'openssl'
require 'pathname'
require 'thread'
require 'uri'

SITE_ROOT = File.expand_path('..', __dir__)
PUBLIC_ROOT = File.join(SITE_ROOT, 'public')
WORKERS = 6
TIMEOUT = 12
ACCEPTED_BLOCKED_STATUSES = [401, 403, 405, 406, 409, 429, 999].freeze
HOST_ACCEPTED_STATUSES = {
  'formspree.io' => [400],
  'www.last.fm' => [600]
}.freeze
KNOWN_INCOMPLETE_TLS_CHAIN_HOSTS = %w[
  ecir2026.eu
  iir2024.uniud.it
  ircdl2025.uniud.it
  smdc.uniud.it
].freeze

unless Dir.exist?(PUBLIC_ROOT)
  warn "ERROR: #{PUBLIC_ROOT} does not exist; build the site first."
  exit 1
end

def external_urls(html)
  values = html.scan(/(?<![:\w-])(?:href|src|action)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))/i)
               .map { |double_quoted, single_quoted, unquoted| double_quoted || single_quoted || unquoted }
  values.each_with_object([]) do |raw_url, urls|
    value = CGI.unescapeHTML(raw_url.to_s.strip)
    next if value.include?('{')

    uri = URI.parse(value)
    next unless %w[http https].include?(uri.scheme&.downcase)
    next if %w[michaelsoprano.com www.michaelsoprano.com].include?(uri.host&.downcase)

    uri.fragment = nil
    urls << uri.to_s
  rescue URI::InvalidURIError
    next
  end
end

def request(uri, method, redirects = 0)
  raise 'too many redirects' if redirects > 5

  request_class = method == :head ? Net::HTTP::Head : Net::HTTP::Get
  request = request_class.new(uri)
  request['User-Agent'] = 'MichaelSoprano.com link checker (+https://michaelsoprano.com/)'
  request['Accept'] = 'text/html,application/pdf,*/*;q=0.8'
  request['Range'] = 'bytes=0-0' if method == :get

  response = Net::HTTP.start(
    uri.host,
    uri.port,
    use_ssl: uri.scheme == 'https',
    open_timeout: TIMEOUT,
    read_timeout: TIMEOUT
  ) { |http| http.request(request) }

  if response.is_a?(Net::HTTPRedirection) && response['location']
    return request(URI.join(uri, response['location']), method, redirects + 1)
  end

  response
end

def check(uri)
  attempts = 0
  loop do
    attempts += 1
    begin
      response = request(uri, :head)
      response = request(uri, :get) if response.code.to_i == 405
      if response.code.to_i.between?(500, 599) && attempts < 2
        sleep 1
        next
      end
      return response
    rescue Net::OpenTimeout, Net::ReadTimeout, EOFError, Errno::ECONNRESET
      raise if attempts >= 2
    end
  end
end

html_paths = Dir.glob(File.join(PUBLIC_ROOT, '**', '*.html')).sort
urls = html_paths.flat_map { |path| external_urls(File.binread(path).force_encoding(Encoding::UTF_8)) }.uniq.sort
queue = Queue.new
urls.each { |url| queue << url }

failures = []
warnings = []
mutex = Mutex.new
workers = Array.new([WORKERS, urls.length].min) do
  Thread.new do
    loop do
      url = queue.pop(true)
      uri = URI.parse(url)
      response = check(uri)
      status = response.code.to_i
      host_accepted = HOST_ACCEPTED_STATUSES.fetch(uri.host.downcase, []).include?(status)
      next if status.between?(200, 399) || ACCEPTED_BLOCKED_STATUSES.include?(status) || host_accepted

      mutex.synchronize { failures << "#{status} #{url}" }
    rescue ThreadError
      break
    rescue OpenSSL::SSL::SSLError => e
      known_incomplete_chain = KNOWN_INCOMPLETE_TLS_CHAIN_HOSTS.include?(uri.host.downcase) &&
                               e.message.include?('unable to get local issuer certificate')
      target = known_incomplete_chain ? warnings : failures
      label = known_incomplete_chain ? 'known incomplete TLS chain' : "#{e.class}: #{e.message}"
      mutex.synchronize { target << "#{label} — #{url}" }
    rescue StandardError => e
      mutex.synchronize { failures << "#{e.class}: #{e.message} — #{url}" }
    end
  end
end
workers.each(&:join)

puts "External links checked: #{urls.length}."
warnings.sort.each { |warning| warn "WARNING: #{warning}" }
if failures.empty?
  puts "External link check passed#{warnings.empty? ? '.' : " with #{warnings.length} known TLS warning(s)."}"
else
  failures.sort.each { |failure| warn "ERROR: #{failure}" }
  warn "External link check failed with #{failures.length} error(s)."
  exit 1
end
