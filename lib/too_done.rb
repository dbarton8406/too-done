require "too_done/version"
require "too_done/init_db"
require "too_done/user"
require "too_done/session"
require "too_done/todo_list"
require "too_done/task"

require "thor"
require "pry"

module TooDone
  class App < Thor

    desc "add 'TASK'", "Add a TASK to a todo list."
    option :list, :aliases => :l, :default => "*default*",
      :desc => "The todo list which the task will be filed under."
    option :date, :aliases => :d,
      :desc => "A Due Date in YYYY-MM-DD format."
    def add(task)
      error_and_exit("ERROR: No user session.") unless Session.last
      error_and_exit("ERROR: Due Date must be in format YYYY-MM-DD") unless options[:date].nil? || options[:date] =~ /^$|^\d{4}-\d{2}-\d{2}$/
      todo_list = current_user.todo_lists.find_or_create_by(name: options[:list])
      new_task = todo_list.tasks.create(name: task, due_date: options[:date])
      options[:tags].each do |tag_name|
        tag = Tag.find_or_create_by(name: tag_name)
        new_task.todo_tags.create(tag: tag)
      end
    end


    desc "edit", "Edit a task from a todo list."
    option :list, :aliases => :l, :default => "*default*",
      :desc => "The todo list whose tasks will be edited."
    def edit
      error_and_exit("ERROR: No user session.") unless Session.last
      open_tasks = invoke "show", [], :list => options[:list]
      regex = /^[#{open_tasks.pluck(:id).join}]$/
      id = prompt_user("Pick a task to edit: ",regex)
      task = open_tasks.find_by(id: id)
      title = prompt_user("Enter a new title: ",/^.+$/)
      due_date = prompt_user("Enter a new due date (or nil for none): ",/^$|^\d{4}-\d{2}-\d{2}$/)
      task.update(name: title, due_date: due_date)
    end

    desc "done", "Mark a task as completed."
    option :list, :aliases => :l, :default => "*default*",
      :desc => "The todo list whose tasks will be completed."

    def done
      error_and_exit("ERROR: No user session.") unless Session.last
      open_tasks = invoke "show", [], :list => options[:list]
      # TODO want to handle completing multiple tasks at the same time??
      error_and_exit("ERROR: No open tasks") if open_tasks.count==0
      regex = /^[#{open_tasks.pluck(:id).join}]$/
      id = prompt_user("Pick a task to edit: ",regex)
      task = open_tasks.find_by(id: id)
      task.update(complete: true)
      puts "Task: #{id} - #{task.name} completed."
    end

    desc "show", "Show the tasks on a todo list in reverse order."
    option :list, :aliases => :l, :default => "*default*",
      :desc => "The todo list whose tasks will be shown."
    option :completed, :aliases => :c, :default => false, :type => :boolean,
      :desc => "Whether or not to show already completed tasks."
    option :sort, :aliases => :s, :enum => ['history', 'overdue'],
      :desc => "Sorting by 'history' (chronological) or 'overdue'.
                                      \t\t\t\t\tLimits results to those with a due date."
    def show
      error_and_exit("ERROR: No user session.") unless Session.last
      todo_list = current_user.todo_lists.find_by(name: options[:list])
      error_and_exit("ERROR: \'#{options[:list]}\' list not found or empty!") unless todo_list
      if options[:sort] == "overdue"
        tasks = todo_list.tasks.where(complete: options[:completed]).where("due_date < ?", DateTime.now).where.not(due_date: nil).order(id: :desc)
      else
        tasks = todo_list.tasks.where(complete: options[:completed]).order(id: :desc)
      end
      message = options[:completed] ? "Completed Tasks" : "Open Tasks"
      puts "#{todo_list.name} List => " + message + " [sorted by: " + options[:sort] + "]"
      tasks.each do |task|
        puts task
      end
      tasks
    end
  end

  desc "delete [LIST OR USER]", "Delete a todo list or a user."
  option :list, :aliases => :l, :default => "*default*",
    :desc => "The todo list which will be deleted (including items)."
  option :user, :aliases => :u,
    :desc => "The user which will be deleted (including lists and items)."
  def delete
    error_and_exit("ERROR: No user session.") unless Session.last
    if(!options[:user].nil? && options[:list]!="*default*") || (options[:user].nil? && options[:list].nil?)
      puts "ERROR: Please specify either a list or a user, but not both!"
      exit
    end
    if(!options[:user].nil?)
      delete = User.find_by(name: options[:user])
      message = "user: #{options[:user]}"
    else
      delete = current_user.todo_lists.find_by(name: options[:list])
      message = "list: #{options[:list]}"
    end
    error_and_exit("ERROR: #{message} not found") if(delete.nil?)

    delete.destroy
    puts "Deletion of #{message} completed."
  end
end

desc "switch USER", "Switch session to manage USER's todo lists."
def switch(username)
  user = User.find_or_create_by(name: username)
  user.sessions.create
end

private
def current_user
  Session.last.user
end

def error_and_exit(text)
  puts text
  exit
end

def prompt_user(text,regex)
  print text
  input = STDIN.gets.chomp
  until input =~ regex
    print text
    input = STDIN.gets.chomp
  end
  input
end

# binding.pry
TooDone::App.start(ARGV)
