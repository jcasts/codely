require 'codely'
require 'sinatra'
require 'cgi'

class Codely::App < Sinatra::Application
  require 'codely/paste'

  PASTE_ATTR = [:lang, :filename, :data, :theme]

  PLAIN_RESP = {
    :not_found => "Not Found",
    :new       => "Hi, this is Codely!\n[v#{Codely::VERSION}]"
  }

  enable :sessions

  set :public_folder, File.join(Codely::ROOT, 'public')
  set :views,         File.join(Codely::ROOT, 'views')


  before do
    @default_lang  = session[:last_lang]  || "Ruby"
    @default_theme = session[:last_theme] || "default"
  end


  after do
    content_type 'text/plain' if plain?
  end


  # Main paste creation interface.
  get '/' do
    @title = "New Paste"
    render_out :new
  end


  # Create a new paste.
  post '/' do
    @paste = Codely::Paste.create( paste_attribs )
    session[:last_lang]  = @paste.lang
    session[:last_theme] = @paste.theme

    redirect_to_paste @paste
  end


  # Used as API upload endpoint.
  # Upload a file in the HTTP body.
  # Returns a 302 with the location of new paste.
  put '/' do
    @paste = Codely::Paste.create( paste_attribs )
    render_out @paste
  end


  # Retrieve an existing paste by id.
  get '/:id' do
    @paste = Codely::Paste.get params[:id]
    render_out 404, :not_found unless @paste

    @title = "View #{@paste.id}"
    render_out @paste
  end


  # Update an existing paste by id.
  post '/:id' do
    @paste = Codely::Paste.get params[:id]
    render_out 404, :not_found unless @paste

    @paste.update(paste_attribs)
    redirect_to_paste @paste
  end


  # Update an existing paste by id, from upload.
  put '/:id' do
    @paste = Codely::Paste.get params[:id]
    render_out 404, :not_found unless @paste

    @paste.update(paste_attribs)
    render_out @paste
  end


  # Delete an existing paste by id.
  delete '/:id' do
    @paste = Codely::Paste.get params[:id]
    render_out 404, :not_found unless @paste

    @paste.destroy
    redirect to('/')
  end


  # Return a hash of paste attributes from params
  # and uploaded file.
  def paste_attribs
    return @attribs if @attribs
    @attribs = {}

    PASTE_ATTR.each do |key|
      @attribs[key] = params[key] if params[key]
    end

    if Hash === params[:file] && params[:file][:tempfile].respond_to?(:read)
      @attribs[:data]       = params[:file][:tempfile].read.strip
      @attribs[:filename] ||= params[:file][:filename]

    elsif !@attribs[:data] && !@attribs.empty?
      # look for uploaded file in INPUT
      data = request.body.read.strip
      @attribs[:data] = data unless data.empty?
    end

    @attribs
  end


  # Check if the response should be plain text or not.
  def plain?
    !request.accept?('text/html') || params[:raw]
  end


  def title
    sub = " - #{@title}" if @title
    "Codely#{sub}"
  end


  def h value
    CGI.escapeHTML value
  end


  def theme_css
    return unless @paste
    "<link href=\"/css/#{h(@paste.theme)}.css\" />"
  end


  # Retrieve the appropriate body string for the given target.
  def body_for target
    case target
    when Codely::Paste
      if params[:raw]
        target.data
      elsif plain?
        target.term
      else
        erb(:show)
      end

    else
      plain? ? PLAIN_RESP[target] : erb(target)
    end
  end


  def redirect_to_paste paste
    redirect to("/#{paste.id}"), paste.id.to_s
  end


  def render_out *args
    code, headers, body = nil

    args.each do |arg|
      case arg
      when Fixnum
        code = arg
      when String
        body = arg
      when Symbol, Codely::Paste
        body = body_for(arg)
      when Hash
        headers = arg
      end
    end

    new_args = [code, headers, body].compact
    halt(*new_args)
  end
end
