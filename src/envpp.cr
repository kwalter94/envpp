# TODO: Write documentation for `Env::Hydrate`
require "./envpp/env_translator"

module Envpp
  VERSION = "0.1.0"

  translator = EnvTranslator.new

  STDIN.each_line do |line|
    puts translator.translate_line(line)
    puts "\n"
  end
end
