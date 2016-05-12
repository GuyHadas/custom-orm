#Custom ORM

A custom ORM inspired by Rails' Active Record.

##Features
 * Create convenient SQL joins using various associations
 * Query the database in a simple and efficient manner
 * User friendly representations of the various models and their data

## Sample Code
```ruby

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

def has_many(name, options = {})
  options = HasManyOptions.new(name, self, options)

  define_method(name) do
    options.model_class.where(options.foreign_key => id)
  end
end

def has_one_through(name, through_name, source_name)

  define_method name do
    self_table = self.class.to_s.downcase + "s"

    through_options = self.class.assoc_options[through_name]
    through_primary_key = through_options.send(:primary_key)
    through_table = through_name.to_s.downcase + "s"

    key = self.send(through_options.send(:foreign_key))

    source_options = through_options.model_class.assoc_options[source_name]
    source_foreign_key = source_options.send(:foreign_key)
    source_primary_key = source_options.send(:primary_key)
    source_table = source_name.to_s.downcase + "s"

    results = DBConnection.execute(<<-SQL)
        SELECT #{source_table}.*
        FROM #{through_table}
        JOIN #{source_table}
          ON #{source_foreign_key} = #{source_table}.#{source_primary_key}
        WHERE #{through_table}.#{through_primary_key} = #{key}
      SQL
    source_options.model_class.new(results.first)
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

  module Searchable

    def where(params)
      where_line = params.keys
      where_line = where_line.map! do |key|
        key.to_s + " = ?"
      end.join(" AND ")

      vals = params.values

      results = DBConnection.execute(<<-SQL, *vals)
        SELECT
          *
        FROM
          #{self.table_name}
        WHERE
          #{where_line}
      SQL
      parse_all(results)
    end
  end
end
```
