require 'yaml'
require 'linguist'

class Codely
  VERSION = '1.0.0'
  ROOT    = File.expand_path(File.join(File.dirname(__FILE__), ".."))

  DEFAULT_CONFIG = YAML.load_file(File.join(ROOT, 'config.yml'))

  LANGUAGES = Linguist::Language.all.map{|l| l.name }
end
