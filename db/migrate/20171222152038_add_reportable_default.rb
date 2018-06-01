class AddReportableDefault < ActiveRecord::Migration[5.1]
  def up
    change_column_default :vehicles, :reportable, true
  end

  def down
    change_column_default :vehicles, :reportable, nil
  end
end
