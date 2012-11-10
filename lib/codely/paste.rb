require 'data_mapper'
require 'linguist'
require 'digest/md5'

class Codely::Paste

  class UnknownLanguage < RuntimeError; end

  include DataMapper::Resource
  include Linguist::BlobHelper

  property :id,         Serial
  property :filename,   String
  property :theme,      String, :default => 'default'
  property :created_at, Time,   :required => true
  property :updated_at, Time,   :required => true
  property :lang,       String, :required => true, :default => "Plain Text"
  property :md5,        String, :required => true
  property :data,       Text,   :required => true
  property :html,       Text,   :required => true
  property :term,       Text,   :required => true


  before :create do |paste|
    paste.created_at = Time.now
  end


  before :save do |paste|
    new_md5          = Digest::MD5.hexdigest paste.data
    paste.updated_at = Time.now

    if new_md5 != paste.md5
      paste.md5 = new_md5
      paste.process_code
      paste.lang = paste.language.name if paste.language
      paste.html = paste.colorize
      paste.term = paste.colorize(:formatter => 'terminal')
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
