require_relative '02_searchable'
require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    options.each do |attr_name, arg|
      instance_variable_set("@#{attr_name}", arg)
    end

    @primary_key ||= :id
    @foreign_key ||= "#{name}_id".to_sym
    @class_name ||= name.to_s.camelcase
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    options.each do |attr_name, arg|
      instance_variable_set("@#{attr_name}", arg)
    end

    @primary_key ||= :id
    @foreign_key ||= "#{self_class_name.to_s.downcase}_id".to_sym
    @class_name ||= name.to_s.singularize.camelcase
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options

    define_method name do
      return nil if self.send(options.foreign_key).nil?

      options.model_class.new DBConnection.execute(<<-SQL).first
        SELECT
          *
        FROM
          #{options.table_name}
        WHERE
          id = #{self.send(options.foreign_key)}
      SQL
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self, options)
    assoc_options[name] = options

    define_method name do
      DBConnection.execute(<<-SQL).map{|result| options.model_class.new(result)}
        SELECT
          *
        FROM
          #{options.table_name}
        WHERE
          #{options.foreign_key} = #{self.send(options.primary_key)}
      SQL
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
