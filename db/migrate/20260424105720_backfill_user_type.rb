class BackfillUserType < ActiveRecord::Migration[8.1]
  def change
    User.where(type: nil).update_all(type: "User::Citizen")
  end
end
