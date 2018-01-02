class AddNtdReportableField < ActiveRecord::Migration
  def change
    add_column :trips, :ntd_reportable, :boolean, default: true
    add_column :repeating_trips, :ntd_reportable, :boolean, default: true
    add_column :runs, :ntd_reportable, :boolean, default: true
    add_column :repeating_runs, :ntd_reportable, :boolean, default: true
    add_column :vehicles, :ntd_reportable, :boolean, default: true
  end
end
