require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    DBConnection.execute(<<-SQL, params.values).map{|results| self.new(results)}
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{params.map{|attr_name, _| "#{attr_name} = ?"}.join(" AND ")}
    SQL
  end
end

class SQLObject
  extend Searchable
end
