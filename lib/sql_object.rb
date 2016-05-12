require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  include ActiveSupport::Inflector

  def self.columns
    if @columns
      @columns
    else
      columns_temp = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{table_name}"
      SQL
      table_name
      @columns = columns_temp[0].map! do |col|
        col.to_sym
      end
    end
  end

  def self.finalize!
    columns.each do |col|
      define_method("#{col}") do
        attributes[col]
      end

      define_method("#{col}=") do |value|
        attributes[col] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        "#{table_name}".*
      FROM
        "#{table_name}"
    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    results.map do |hash|
      self.new(hash)
    end
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id: id)
      SELECT
        "#{table_name}".*
      FROM
        "#{table_name}"
      WHERE
        "#{table_name}".id = :id
    SQL
    result.empty? ? nil : self.new(result.first)
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name)
      send("#{attr_name}=".to_sym, value)
    end
  end

  def attributes
    @attributes ||= {}
  end


  def attribute_values
    self.class.columns.map do |col|
      send(col)
    end
  end

  def insert
    col_names = self.class.columns.join(", ")
    question_marks = (["?"] * self.class.columns.length).join(", ")
    vals = attribute_values

    DBConnection.execute(<<-SQL, *vals)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_line = []
    self.class.columns.each do |col|
      set_line << col.to_s + " = ?"
    end
    set_line= set_line.join(", ")
    vals = attribute_values

    DBConnection.execute(<<-SQL, *vals, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        #{self.class.table_name}.id = ?
    SQL

  end

  def save
    self.id.nil? ? insert : update
  end
end
