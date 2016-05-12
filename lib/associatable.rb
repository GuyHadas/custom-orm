require_relative 'searchable'
require 'active_support/inflector'

class AssocOptions
  include ActiveSupport::Inflector

  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    self.model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  attr_reader :foreign_key, :primary_key, :class_name
  def initialize(name, options = {})
    fk = options[:foreign_key] ? options[:foreign_key]: (name.to_s + "_id").to_sym
    pk = options[:primary_key] ? options[:primary_key] : :id
    cn = options[:class_name] ? options[:class_name] : name.to_s.capitalize

    @foreign_key = fk
    @primary_key = pk
    @class_name = cn
  end
end

class HasManyOptions < AssocOptions

  def initialize(name, self_class_name, options = {})
    fk = options[:foreign_key] ? options[:foreign_key] : (self_class_name.to_s.downcase + "_id").to_sym
    pk = options[:primary_key] ? options[:primary_key] : :id
    cn = options[:class_name] ? options[:class_name] : name.to_s.singularize.capitalize

    @foreign_key = fk
    @primary_key = pk
    @class_name = cn
  end
end

module Associatable
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      key_val = send(self.class.assoc_options[name].foreign_key)

      self.class.assoc_options[name].model_class.find(key_val)
    end
  end


  def has_many(name, options = {})
    options = HasManyOptions.new(name, self, options)

    define_method(name) do
      options.model_class.where(options.foreign_key => id)
    end
  end

  def assoc_options
    @assoc_options ||= {}
    @assoc_options
  end
end

class SQLObject
  extend Associatable
end
