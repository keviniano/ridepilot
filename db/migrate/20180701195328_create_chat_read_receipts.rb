class CreateChatReadReceipts < ActiveRecord::Migration[5.1]
  def change
    create_table :chat_read_receipts do |t|
      t.references :run, foreign_key: true
      t.references :message, foreign_key: true
      t.integer :read_by_id

      t.timestamps
    end
  end
end
