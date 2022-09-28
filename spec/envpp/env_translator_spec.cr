require "../spec_helper"
require "../../src/envpp/env_translator"

def create_translator
  env_table = Envpp::EnvTable.new({ "foo" => "bar", "bar" => "foo" })
  Envpp::EnvTranslator.new(env_table)
end

describe Envpp::EnvTranslator do
  describe "translate_line(line)" do
    it "replaces ${variable} with environment variable value" do
      translator = create_translator
      line = translator.translate_line("My ${bar}${foo}")
      line.should eq("My foobar")
    end

    it "replaces $(variable) with environment variable value" do
      translator = create_translator
      line = translator.translate_line("My $(foo)$(bar)")
      line.should eq("My barfoo")
    end

    it "does not translate escaped variables" do
      translator = create_translator
      line = translator.translate_line("My \\$(foo)$(bar)")
      line.should eq("My $(foo)foo")
    end

    it "replaces ${variable:default} with default if environment variable is not found" do
      translator = create_translator
      line = translator.translate_line("${vogon:foobar}")
      line.should eq("foobar")
    end

    it "caches previously encountered default variable values" do
      translator = create_translator
      translator.translate_line("${vogon:foobar}")
      line = translator.translate_line("$(vogon)")
      line.should eq("foobar")
    end

    it "throws a TranslationError for malformed variables" do
      translator = create_translator
      expect_raises(Envpp::TranslationError) { translator.translate_line("$foo") }
      expect_raises(Envpp::TranslationError) { translator.translate_line("${foo)") }
      expect_raises(Envpp::TranslationError) { translator.translate_line("${-1foo}") }
    end
  end
end
