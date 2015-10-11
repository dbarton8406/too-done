class CreateTask < ActiveRecord::Migration
  def up
   create_table : tasks do |t|
   	# belongs_to list in model
   	t.string :name, null: false
   	t.interger :todo_list_id, null: false
   	t.datetime :task_due
   	t.boolean :task_completed
   	
    end
  end

  def down
    drop_table :items
  end
end