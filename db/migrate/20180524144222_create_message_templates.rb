class CreateMessageTemplates < ActiveRecord::Migration[5.1]
  def change
    create_table :message_templates do |t|
      t.text :message
      t.references :provider, foreign_key: true
      t.string :type

      t.timestamps
    end
  end
end
