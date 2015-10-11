class CreateList < ActiveRecord::Migration
  def up
  	create_table :list do |t|
     # todo belongs to users model
     t.string:name ,null: false
     t.interger :user_id, null: false
     t.timestamps null :false
    end
  end

  def down
    drop_table :lists
  end
end