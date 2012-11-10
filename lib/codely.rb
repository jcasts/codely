require 'yaml'

class Codely
  VERSION = '1.0.0'
  ROOT    = File.expand_path(File.join(File.dirname(__FILE__), ".."))

  DEFAULT_CONFIG = YAML.load_file(File.join(ROOT, 'config.yml'))
end
