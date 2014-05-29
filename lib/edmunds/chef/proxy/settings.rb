require 'yaml'
require 'deep_symbolize'

module Settings
  extend self

  @_settings = {}
  attr_reader :_settings

  def load!(filename)
    newsets = YAML::load_file(filename)
    newsets.extend DeepSymbolizable
    newsets = newsets.deep_symbolize
    deep_merge!(@_settings, newsets)
    @_settings
  end

  # Deep merging of hashes
  def deep_merge!(target, data)
    merger = proc{|key, v1, v2|
      Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    target.merge! data, &merger
  end

  def method_missing(name, *args, &block)
    @_settings[name.to_sym] ||
    fail(NoMethodError, "unknown configuration root #{name}", caller)
  end

end

