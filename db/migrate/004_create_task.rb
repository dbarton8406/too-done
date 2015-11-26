class CreateTask < ActiveRecord::Migration
  def up
   create_table : tasks do |t|
   	belongs_to :user 
   	t.string :name, null: false
   	t.interger :todo_list_id, null: false
   	t.datetime :task_due_by
   	t.boolean :task_complete, null:false
   	
    end
  end

  def down
    drop_table :items
  end
end