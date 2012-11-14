require 'net/http'

class Codely::Client

  ##
  # Create a new client for a given host and port.

  def initialize host, port
    
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
    
  end


  ##
  # Delete the Paste with the given ID.

  def delete id
    
  end


  ##
  # Get the Paste body for the given ID.
  # Returns a String, or nil if not found.

  def get id
    
  end


  ##
  # Update the Paste with the given ID.
  # Supported options are:
  # :data:: String or IO - the contents to paste.
  # :filename:: String - the name of the file uploaded.
  # :lang:: String - the language parser to use. See Codely::LANGUAGES.

  def update id, opts={}
    
  end
end
