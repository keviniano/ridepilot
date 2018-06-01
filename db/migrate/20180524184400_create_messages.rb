class CreateMessages < ActiveRecord::Migration[5.1]
  def change
    create_table :messages do |t|
      t.references :provider
      t.string :type
      t.text :body
      t.integer :sender_id
      t.integer :reader_id
      t.datetime :read_at

      t.timestamps
    end

    add_index :messages, :sender_id           
    add_index :messages, :reader_id               
  end
end
