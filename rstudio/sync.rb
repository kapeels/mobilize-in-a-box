#!/bin/ruby

require 'mysql2'
require 'daybreak'

# ohmage mysql location, user/pass source
mysql_host = 'mysql'
mysql_user = 'root'
mysql_password = ENV['MYSQL_ENV_MYSQL_ROOT_PASSWORD']
mysql_db = ARGV[0]
# all users from this query will be created. remove usernames that don't conform to unix standards.
mysql_user_query = 'select distinct user.username,user.password from user where username not like "%.%"'

# flat file db to hold sync password state
daybreak_db_file = "/tmp/account_sync.db"

# open db connections
db = Daybreak::DB.new daybreak_db_file
mysql = Mysql2::Client.new(:host => mysql_host, :username => mysql_user, :password => mysql_password, :database => mysql_db)

new_users = [] # array of new users to sync
changed_users = [] # array of users with changed passwords to sync
begin
  mysql.query(mysql_user_query).each do |x|
    @username = x['username']
    @password = x['password']
    if !db.keys.include? @username # if user is not in db, assume they are new.
      db[@username] = x 
      new_users.push(x)
    else
      if db[@username]['password'] != @password # if password hashes don't match, set new password to be synced.
        changed_users.push(x)
        db[@username] = x
      end
    end
  end
  db.close # no more daybreak db needed
  
  if new_users.any? or changed_users.any? # only ssh if there are users to update
    new_users.each do |u| # exec! ensures synchronous commands.
      `echo #{u['username']}:dummy::::/home/#{u['username']}:/bin/nologin | newusers`
      `echo '#{u['username']}:#{u['password']}' | chpasswd -e`
    end
    changed_users.each do |u|
      `echo '#{u['username']}:#{u['password']}' | chpasswd -e`
    end
  end
rescue Exception => e # nice error handling, man.
  p "#{Time.now.asctime()}: Sync Error, password sync potentially failed: #{e}"
end

p "#{Time.now.asctime()}: Sync Finished. New Users(#{new_users.count}), Updated Passwords(#{changed_users.count})"
