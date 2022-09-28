require "../spec_helper"
require "../../src/envpp/env_translator"

class EnvTableDouble < Envpp::EnvTable
  def has_key?(name : String)
    !fetch(name).nil?
  end

  def fetch(name : String, default : String? = nil)
    @@env_vars ||= { "foo" => "bar", "bar" => "foo" }
    @@env_vars.try { |vars| vars.fetch(name, default) }
  end
end

def create_translator
  Envpp::EnvTranslator.new(EnvTableDouble.new)
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
