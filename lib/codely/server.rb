require 'codely'
require 'unicorn/launcher'
require 'rainbows'

class Codely::Server

  def self.start opts=nil
    opts ||= Codely::DEFAULT_CONFIG['server']
  end


  def self.stop
    
  end


  def self.restart
    
  end
end
