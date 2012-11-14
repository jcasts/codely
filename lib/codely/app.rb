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
    @alert  = session[:alert]
    @notice = session[:notice]
  end


  after do
    session.delete(:alert)  if @alert
    session.delete(:notice) if @notice

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

    if @paste.saved?
      redirect_to_paste @paste
    else
      @alert = "Could not save paste. Please try again later."
      render_out(:new)
    end
  end


  # Used as API upload endpoint.
  # Upload a file in the HTTP body.
  # Returns a 302 with the location of new paste.
  put '/' do
    @paste = Codely::Paste.create( paste_attribs )
    if @paste.saved?
      render_out @paste.id.to_s
    else
      render_out "Error saving paste"
    end
  end


  # Get a the language for a filename
  post '/lang' do
    lang = Linguist::Language.find_by_filename(params[:filename]).first
    lang ? lang.name : "Plain Text"
  end


  # Retrieve an existing paste by id.
  get '/:id' do
    @paste = Codely::Paste.get params[:id]
    render_out 404, :not_found unless @paste

    @paste.update :viewed_at => Time.now
    @title = "View #{@paste.id}"
    render_out @paste
  end


  # Paste edit page by id.
  get '/:id/edit' do
    @paste = Codely::Paste.get params[:id]
    render_out 404, :not_found unless @paste

    @title = "Edit #{@paste.id}"
    render_out :edit
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
    render_out @paste.id.to_s
  end


  # Delete an existing paste by id.
  delete '/:id' do
    @paste = Codely::Paste.get params[:id]
    render_out 404, :not_found unless @paste

    @paste.destroy ? "Deleted" : "Failed"
  end


  # Delete an existing paste by id.
  post '/:id/delete' do
    @paste = Codely::Paste.get params[:id]
    render_out 404, :not_found unless @paste

    if @paste.destroy
      session[:notice] = "Deleted paste ##{@paste.id}"
      redirect to('/')
    else
      session[:alert] = "Could not delete paste ##{@paste.id}"
      redirect_to_paste @paste
    end
  end


  # Return a hash of paste attributes from params
  # and uploaded file.
  def paste_attribs
    return @attribs if @attribs
    @attribs = {}

    PASTE_ATTR.each do |key|
      @attribs[key] = params[key] if params[key] && !params[key].empty?
    end

    if Hash === params[:file] && params[:file][:tempfile].respond_to?(:read)
      @attribs[:data]     ||= params[:file][:tempfile].read.strip
      @attribs[:filename] ||= params[:file][:filename]

    elsif !@attribs[:data] && request.request_method == "PUT"
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


  ##
  # View Helpers
  ##


  def title
    sub = " - #{@title}" if @title
    "Codely#{sub}"
  end


  def h value
    CGI.escapeHTML value.to_s
  end


  def theme_css
    return unless @paste
    "<link href=\"/css/themes/#{h(@paste.theme)}.css\" />"
  end


  def paste_id
    @paste.id if @paste
  end


  def languages
    Codely::LANGUAGES
  end


  def curr_data
    @paste.data if @paste
  end


  def curr_lang
    h(@paste ? @paste.lang.to_s : @default_lang)
  end


  def curr_filename
    h(@paste ? @paste.filename.to_s : "")
  end
end
