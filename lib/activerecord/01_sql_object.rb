require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  def self.columns
    @columns ||= DBConnection.execute2(<<-SQL).first.map(&:to_sym)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    @columns
  end

  def self.finalize!
    self.columns.each do |name|
      define_method name do
        attributes[name]
      end

      define_method "#{name}=" do |arg|
        attributes[name] = arg
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= ActiveSupport::Inflector.tableize("#{self}")
  end

  def self.all
    self.parse_all DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
  end

  def self.parse_all(results)
    results.map do |result|
      self.new result
    end
  end

  def self.find(id)
    obj = DBConnection.execute(<<-SQL).first
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = #{id}
    SQL

    obj.nil? ? obj : self.new(obj)
  end

  def initialize(params = {})
    params.each do |attr_name, arg|
      raise "unknown attribute '#{attr_name}'" unless
        self.class.columns.include? attr_name.to_sym

      send("#{attr_name}=", arg)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    DBConnection.execute(<<-SQL, attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{self.class.columns[1..-1].join(", ")})
      VALUES
        (#{Array.new(self.class.columns.length - 1){"?"}.join(", ")})
    SQL

    attributes[:id] = DBConnection.last_insert_row_id
  end

  def update
    DBConnection.execute(<<-SQL, attribute_values.rotate)
      UPDATE
        #{self.class.table_name}
      SET
         #{self.class.columns[1..-1].map{|attr_name| "#{attr_name}= ?"}.join(", ")}
      WHERE
        id = ?
    SQL
  end

  def save
    attributes[:id].nil? ? insert : update
  end
end
