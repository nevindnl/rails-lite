require_relative '03_associatable'

module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options
  def has_one_through(name, through_name, source_name)
    through_options = self.assoc_options[through_name]

    define_method name do
      source_options = through_options.model_class.assoc_options[source_name]

      through = through_options.table_name
      source = source_options.table_name

      source_options.model_class.new DBConnection.execute(<<-SQL).first
        SELECT
          #{source}.*
        FROM
          #{source}
        JOIN
          #{through}
          ON #{through}.#{source_options.foreign_key} = #{source}.#{source_options.primary_key}
        WHERE
          #{through}.#{through_options.primary_key} = #{self.send(through_options.foreign_key)}
      SQL
    end
  end

  def has_many_through(name, through_name, source_name)
    through_options = self.assoc_options[through_name]

    define_method name do
      source_options = through_options.model_class.assoc_options[source_name]

      through = through_options.table_name
      source = source_options.table_name

      DBConnection.execute(<<-SQL).map{|result| source_options.model_class.new(result)}
        SELECT
          #{source}.*
        FROM
          #{source}
        JOIN
          #{through}
          ON #{through}.#{source_options.foreign_key} = #{source}.#{source_options.primary_key}
        WHERE
          #{through}.#{through_options.primary_key} = #{self.send(through_options.foreign_key)}
      SQL
    end
  end
end
