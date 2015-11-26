module TooDone
  class User < ActiveRecord::Base
    has_many :sessions, :dependent => :destroy
    has_many :todo_list, :dependent => :destroy
  end
end
