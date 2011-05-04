require 'rubygems'
require 'dm-core'
require 'dm-migrations'
require './lib/livern/item.rb'

class Database
  def connect
    DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite3:dev.sqlite3')
    self
  end

  def migrate
    DataMapper.auto_migrate!
    self
  end
end
