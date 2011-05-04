require 'database.rb'

desc 'Setup Database'
task 'db:set' do
  puts 'Setup Database...'
  Database.new.connect.migrate
end
