require "dotenv"
require "log"
require "option_parser"

require "./envpp/env_translator"

module Envpp
  VERSION = "0.1.0"

  use_system_env = false
  dotenv_file : String? = nil

  OptionParser.parse do |parser|
    parser.banner = "USAGE: envpp < source-file > output-file"

    parser.on("--use-system-env", "Requests use of system environment variables") { use_system_env = true }
    parser.on("--env-file=dotenv-file", "Manually specify a dotenv file") { |path| dotenv_file = path }
    parser.on("-h", "--help", "Print help information") do
      puts(parser)
      exit(0)
    end
  end

  Log.warn { "Ignoring #{dotenv_file} to use --use-system-env flag" } if dotenv_file && use_system_env

  env_source = if use_system_env
                 ENV
               elsif dotenv_file
                 dotenv_file.try { |file| Dotenv.load(file) }
               else
                 Dotenv.load
               end

  raise "Failed to load environment variables" if env_source.nil?

  env_table = EnvTable.new(env_source)
  translator = EnvTranslator.new(env_table)

  STDIN.each_line do |line|
    puts translator.translate_line(line)
    puts "\n"
  end
end
