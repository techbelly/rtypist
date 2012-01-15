require 'optparse'
require 'ostruct'

module Rtypist
  class Cli
    def self.parse_options(program,args)
      options = OpenStruct.new

      opts = OptionParser.new do |opts|
        executable = File.basename(program)
        opts.banner = "Usage: #{executable} [options]"
        opts.separator ""
        
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end

        opts.on_tail("--version", "Show version") do
           puts Rtypist::VERSION
           exit
        end
      end
      opts.parse(args)
      options
    end

    def self.execute(program,args)
      options = parse_options(program,args)
      app = Rtypist::Application.new(options)
      app.start
    end
  end
end
