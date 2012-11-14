require 'data_mapper'
require 'digest/md5'

DataMapper.setup(:default, 'sqlite:///Users/jcastagna/codely/data.db')

class Codely::Paste

  class UnknownLanguage < RuntimeError; end

  include Linguist::BlobHelper
  include DataMapper::Resource

  property :id,         Serial
  property :filename,   String
  property :theme,      String, :default => 'default'
  property :created_at, Time,   :required => true
  property :updated_at, Time,   :required => true
  property :viewed_at,  Time,   :required => true
  property :lang,       String, :required => true, :default => "Plain Text"
  property :md5,        String, :required => true
  property :data,       Text,   :required => true
  property :html,       Text,   :required => true
  property :term,       Text,   :required => true


  before :valid? do
    if !self.id
      time = Time.now
      self.created_at = time
      self.updated_at = time
      self.viewed_at  = time
      self.prerender
    end
  end


  before :save do |paste|
    paste.updated_at = Time.now
    paste.prerender
  end


  def prerender
    new_md5 = Digest::MD5.hexdigest self.data

    if new_md5 != self.md5
      self.md5 = new_md5
      self.lang = self.language.name if self.language
      self.html = self.colorize_without_wrapper
      self.term = self.colorize(:formatter => 'terminal')
    end
  end


  def size
    self.data.to_s.bytesize
  end


  def language
    Linguist::Language.find_by_name(self.lang) ||
      Linguist::Language.find_by_filename(self.filename.to_s).first
  end


  def language= name
    self.lang = name
  end
end

DataMapper.finalize
DataMapper.auto_upgrade!
