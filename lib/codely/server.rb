require 'codely'
require 'unicorn/launcher'
require 'rainbows'

class Codely::Server

  class Error < RuntimeError; end


  def self.start opts={}
    host = opts.delete(:host) || "localhost:70741"
    server = new host, opts
  end


  def self.stop opts={}
    
  end


  def self.restart opts={}
    
  end


  attr_reader :host, :status

  def initialize host, opts={}
    @host = host
    @status = 'unknown status'
  end
end
