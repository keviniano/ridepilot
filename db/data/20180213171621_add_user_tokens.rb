class AddUserTokens < ActiveRecord::Migration[5.1]
  def up
    User.unscoped.where(authentication_token: nil).each do |user|
      user.save(validate:false)
    end
  end

  def down
    User.all.update_all(authentication_token: nil)
  end
end