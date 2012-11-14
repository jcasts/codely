require 'codely'
require 'optparse'

class Codely::Cmd

  ##
  # Main entry point for running the Codely client command.

  def self.run_client argv=ARGV
    require 'codely/client'

    options = parse_client_argv argv
    cl = Codely::Client.new options.delete(:host)

    resp =
      case options[:action]
      when :get
        cl.get options[:id]
      when :create
        cl.create options.delete(:data), options
      when :delete
        cl.delete options[:id]
      when :update
        cl.update options.delete(:id), options
      end

    puts resp

  rescue Codely::Client::Error => e
    $stderr.puts "ERROR: #{e.message}"
  rescue OptionParser::ParseError => e
    $stderr.puts "ERROR: #{e.message}\nUse codely --help for usage info."
  end


  def self.run_server argv=ARGV
    
  end


  def self.run_config argv=ARGV
    
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

      opt.on('-c', '--config PATH', 'Path to alternate config file') do |val|
        options[:config] = File.read val
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

    if !argv.empty?
      begin
        filepath = argv.pop
        options[:data] = File.open(filepath, "rb")
      rescue => e
        $stderr.puts "ERROR: Could not open file #{filepath}"
        exit 1
      end
    end

    options[:data] ||= $stdin if !$stdin.tty?

    if !options[:action] && options[:data]
      options[:action] = options[:paste_id] ? :update : :create
    end

    if !options[:data] && !options[:id]
      $stderr.puts "\nPlease specify a data source or paste id."
      puts opts
      exit 1
    end

    options[:action] ||= :get
    options
  end
end
