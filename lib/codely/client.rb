require 'codely'
require 'cgi'
require 'net/http'

class Codely::Client

  PASTE_ATTR = [:lang, :filename]

  ##
  # Create a new client for a given host and port.

  def initialize host, port
    @host = host
    @port = port
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
    req = Net::HTTP::Put.new "/#{build_query(opts)}", @headers

    if data.respond_to?(:read)
      req.body_stream = data
    else
      req.body = data.to_s
    end

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
    req = Net::HTTP::Put.new "/#{id}#{build_query(opts)}", @headers

    if opts[:data].respond_to?(:read)
      req.body_stream = data
    elsif opts[:data]
      req.body = data.to_s
    end

    make_request(req)
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


  def make_request req
    res = Net::HTTP.start(@host, @port) do |http|
      http.request(req)
    end

    res.body.strip

  rescue
    return nil
  end
end
