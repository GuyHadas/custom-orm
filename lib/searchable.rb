require_relative 'db_connection'
require_relative 'sql_object'

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

class SQLObject
  extend Searchable
end
