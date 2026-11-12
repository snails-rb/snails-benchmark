# The benchmark's single-row read resource. Column readers and COLUMNS come
# from db/schema.sql through gen/model_columns.rb; this file declares only the
# table, as the table-oriented model layer expects.
class Item < Sqlx::Base
  def self.table_name = "items"
end
