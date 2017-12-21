class CreateSavedCustomReports < ActiveRecord::Migration
  def change
    create_table :saved_custom_reports do |t|
      t.references :custom_report, index: true
      t.references :provider, index: true
      t.string :name
      t.integer :date_range_type
      t.text :report_params

      t.timestamps
    end
  end
end
