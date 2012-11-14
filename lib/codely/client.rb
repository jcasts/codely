require 'codely'
require 'cgi'
require 'net/http'

class Codely::Client

  class Error < RuntimeError; end
  class EmptyData < Error; end
  class InvalidHost < Error; end
  class ConnectionError < Error; end
  class SSLError < Error; end

  PASTE_ATTR = [:lang, :filename]

  attr_accessor :host, :port, :ssl, :prefix

  ##
  # Create a new client for a given host and port:
  #
  #   # Simple Host:Port setup
  #   Codely::Client.new "localhost:80"
  #
  #   # Setup with SSL
  #   Codely::Client.new "https://host.com"
  #
  #   # Supports path prefixes
  #   Codely::Client.new "https://host.com/codely"

  def initialize host
    host = "http://#{host}" if String === host && host !~ %r{^\w+://}
    host = URI.parse(host.to_s) unless URI === host

    @ssl    = host.scheme.to_s.downcase == 'https'
    @host   = host.host || 'localhost'
    @port   = host.port || 80
    @prefix = host.path unless host.path.to_s =~ /^\/?$/
    @headers = {"Accept" => "text/plain"}
  end


  ##
  # Upload a new Paste. The data argument may be a String or
  # any object responding to `read'.
  # Supported options are:
  # :filename:: String - the name of the file uploaded.
  # :lang:: String - the language parser to use. See Codely::LANGUAGES.
  #
  # Returns the ID of the newly created Paste.

  def create data, opts={}
    req = req = put_request(opts.merge(:data => data))
    make_request(req)
  end


  ##
  # Delete the Paste with the given ID.

  def delete id
    req = Net::HTTP::Delete.new "/#{id}", @headers
    make_request(req)
  end


  ##
  # Get the Paste body for the given ID.
  # Returns a String, or nil if not found.

  def get id, raw=true
    query = "?raw=1" if raw
    req = Net::HTTP::Get.new "/#{id}#{query}", @headers
    make_request(req)
  end


  ##
  # Update the Paste with the given ID.
  # Supported options are:
  # :data:: String or IO - the contents to paste.
  # :filename:: String - the name of the file uploaded.
  # :lang:: String - the language parser to use. See Codely::LANGUAGES.

  def update id, opts={}
    req = put_request(opts.merge(:id => id))
    make_request(req)
  end


  ##
  # Return the full url for the given Paste ID.

  def paste_url id
    host = "#{@ssl ? "https" : "http"}://#{@host}#{":#{@port}" if @port != 80}"
    File.join(*[host, @prefix, id].compact)
  end


  private

  def build_query opts
    query = []

    PASTE_ATTR.each do |key|
      (query << "#{key}=#{CGI.escape(opts[key])}") if opts[key]
    end

    return if query.empty?

    "?#{query.join("&")}"
  end


  def put_request opts
    opts[:filename] ||= File.basename(opts[:data].path) if
      opts[:data].respond_to?(:path)

    req = Net::HTTP::Put.new "/#{opts[:id]}#{build_query(opts)}", @headers

    if opts[:data].respond_to?(:read)
      req.body = opts[:data].read
    elsif opts[:data]
      req.body = opts[:data].to_s
    end

    req
  end


  def make_request req
    if @prefix
      path = File.join(@prefix, req.instance_variable_get("@path"))
      req.instance_variable_set("@path", path)
    end

    http = Net::HTTP.new(@host, @port)
    http.use_ssl = @ssl

    res = http.request(req)

    raise InvalidHost, "#{@host}:#{@port} is not a valid Codely server" unless
      res['Codely-Version']

    res.body.strip

  rescue SocketError
    raise ConnectionError, "Could not connect to #{@host}:#{@port}"

  rescue OpenSSL::SSL::SSLError
    raise SSLError, "Could verify SSL connection to #{@host}:#{@port}"

  #rescue
  #  return nil
  end
end
