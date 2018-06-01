class ChangeLookupTableColumnName < ActiveRecord::Migration[5.1]
  def change
    rename_column :lookup_tables, :model_name, :model_name_str
    rename_column :provider_lookup_tables, :model_name, :model_name_str
  end
end
