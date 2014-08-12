require 'codely'
require 'optparse'
require 'yaml'

class Codely::Cmd

  class Error < RuntimeError; end

  SERVER_CONFIG_FILE = File.expand_path "~/.codelyd"
  SERVER_DEFAULT_CONFIG = {
    "host"         => "0.0.0.0:70741",
    "pid"          => File.expand_path("~/codely.pid"),
    "instances"    => 1,
    "connections"  => 50,
    "threads"      => 10,
    "max_file_mb"  => 1
  }

  CLIENT_CONFIG_FILE = File.expand_path "~/.codely"
  CLIENT_DEFAULT_CONFIG = {
    'hosts' => {'default' => 'localhost:70741'}
  }

  ##
  # Main entry point for running the Codely client command.

  def self.run_client argv=ARGV
    require 'codely/client'

    options = parse_client_argv argv
    cl = Codely::Client.new options.delete(:host)

    resp =
      case options[:action]
      when :get
        cl.get options[:paste_id]
      when :create
        cl.paste_url cl.create(options.delete(:data), options)
      when :delete
        cl.delete options[:paste_id]
      when :update
        cl.paste_url cl.update(options.delete(:paste_id), options)
      end

    puts resp

  rescue Codely::Client::Error => e
    error_and_exit! e.message
  end


  ##
  # Main entry point for running the Codely server daemon.

  def self.run_server argv=ARGV
    require 'codely/server'
    options = parse_server_argv argv

    server =
      case options[:action]
      when 'start'
        require 'codely/db'
        puts "Preparing DB"
        Codely::DB.setup
        puts "Starting Codely daemon..."
        Codely::Server.start options

      when 'stop'
        puts "Stopping Codely daemon..."
        Codely::Server.stop options

      when 'restart'
        puts "Restarting Codely daemon..."
        Codely::Server.restart options
      end

    puts "Codely server #{server.status} on socket #{server.host}"

  rescue Codely::Server::Error => e
    error_and_exit! e.message
  end


  def self.parse_server_argv argv
    options = {}

    opts = OptionParser.new do |opt|
        opt.program_name = File.basename $0
        opt.version = Codely::VERSION
        opt.release = nil

        opt.banner = <<-STR

#{opt.program_name} #{opt.version}

Codely server daemon.

  Usage:
    #{opt.program_name} --help
    #{opt.program_name} --version
    #{opt.program_name} action [options]

  Examples:
    #{opt.program_name} start -h 0.0.0.0:54321
    #{opt.program_name} restart -r path/mylib.rb
    #{opt.program_name} stop

  Options:
        STR

      opt.on('-h', '--host STR',
        'TCP/Unix socket to bind to <host[:port]>') do |val|
        options[:host] = val
      end

      opt.on('-p', '--pid PATH', 'Path to pid file') do |val|
        options[:pid] = val
      end

      opt.on('-c', '--config PATH', 'Path to config file') do |val|
        options[:config_path] = val
      end

      opt.on('-?', '--help', 'Show this screen') do
        puts opt
        exit
      end

      opt.on('-v', '--version', 'Show version and exit') do
        puts Codely::VERSION
        exit
      end
    end

    opts.parse! argv

    options[:action] = argv.shift

    unless options[:action]
      $stderr.puts "\nPlease specify an action to perform."
      puts opts
      exit 1
    end

    raise Error, "Unknown action `#{options[:action]}'" unless
      %w{start stop restart}.include?(options[:action])

    options

  rescue Error, OptionParser::ParseError => e
    error_and_exit! "#{e.message}
Use #{opts.program_name} --help for usage info."
  end



  def self.parse_client_argv argv
    options = {}

    opts = OptionParser.new do |opt|
        opt.program_name = File.basename $0
        opt.version = Codely::VERSION
        opt.release = nil

        opt.banner = <<-STR

#{opt.program_name} #{opt.version}

Make and edit Codely pastes.

  Usage:
    #{opt.program_name} --help
    #{opt.program_name} --version
    #{opt.program_name} [options] [file]

  Examples:
    #{opt.program_name} path/to/file.rb
    #{opt.program_name} -p 123
    #{opt.program_name} -d 123
    #{opt.program_name} -p 123 path/to/new_file.rb
    cat path/to/file.rb | #{opt.program_name}

  Options:
        STR

      opt.on('-p', '--paste ID', 'ID of the paste to work with') do |val|
        options[:paste_id] = val
      end

      opt.on('-f', '--filename STR', 'Name the file on the server') do |val|
        options[:filename] = val
      end

      opt.on('-l', '--language STR', 'Language for submitted paste') do |val|
        options[:lang] = val
      end

      opt.on('-d', '--delete ID', 'Delete paste with given ID') do |val|
        options[:paste_id] = val
        options[:action]   = :delete
      end

      opt.on('-h', '--host STR', 'Remote <host[:port]> or alias') do |val|
        options[:host] = val
      end

      opt.separator <<-STR

  Config Options:
      STR

      opt.on('--hosts', 'Display all saved hosts') do
        options[:show_hosts] = true
      end

      opt.on('--alias STR', 'Use with -h so save the host as an alias') do |val|
        options[:save_host] = val
      end

      opt.on('--rm-alias STR', 'Delete a saved host alias') do |val|
        options[:del_host] = val
      end

      opt.on('-c', '--config PATH', 'Path to alternate config file') do |val|
        options[:config_path] = val
      end

      opt.on('-?', '--help', 'Show this screen') do
        puts opt
        exit
      end

      opt.on('-v', '--version', 'Show version and exit') do
        puts Codely::VERSION
        exit
      end
    end

    opts.parse! argv

    config = process_client_config options

    if !options[:host] && config['hosts']
      options[:host] = config['hosts'][options[:host]] ||
                       config['hosts']['default']
    end

    if !argv.empty?
      begin
        filepath = argv.pop
        options[:data] = File.open(filepath, "rb")
      rescue => e
        error_and_exit! "Could not open file #{filepath}"
      end
    end

    options[:data] ||= $stdin if !$stdin.tty?

    if !options[:action] && options[:data]
      options[:action] = options[:paste_id] ? :update : :create
    end

    if !options[:data] && !options[:paste_id]
      $stderr.puts "\nPlease specify a data source or paste ID."
      puts opts
      exit 1
    end

    options[:action] ||= :get
    options

  rescue Error, OptionParser::ParseError => e
    error_and_exit! "#{e.message}
Use #{opts.program_name} --help for usage info."
  end


  def self.process_client_config options={}
    config      = CLIENT_DEFAULT_CONFIG
    config_file = options[:config_path] || CLIENT_CONFIG_FILE
    config      = YAML.load_file(config_file) if File.file?(config_file)

    if options[:show_hosts]
      puts config['hosts'].map{|key, val| "#{key}:\t\t#{val}"}.join("\n")
      write_yml_and_exit! config_file, config

    elsif options[:save_host]
      raise Error, "Specify a host with -h to save alias" if
        !options[:host]
      config['hosts'][options[:save_host]] = options[:host]
      puts "Writing #{options[:save_host]} to config..."
      write_yml_and_exit! config_file, config

    elsif options[:del_host]
      config['hosts'].delete(options[:del_host])
      puts "Removing #{options[:del_host]} from config..."
      write_yml_and_exit! config_file, config
    end

    config
  end


  def self.write_yml_and_exit! path, data
    File.open(path, "w"){|f| f.write data.to_yaml }
    exit
  end


  def self.error_and_exit! msg, code=1
    $stderr.puts "ERROR: #{msg}"
    exit 1
  end
end
