require 'data_mapper'
require 'codely/paste'

class Codely::DB

  class Error < RuntimeError; end

  def self.setup opts={}
    connect opts
    DataMapper.finalize
    DataMapper.auto_upgrade!
  end


  def self.connect opts={}
    host = 'sqlite:///Users/jcastagna/codely/data.db'
    DataMapper.setup(:default, host)
  rescue => e
    raise Error, "Could not connect to DB #{host}"
  end
end
