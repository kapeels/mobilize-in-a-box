#!/bin/ruby
require 'mysql2'
require 'daybreak'
# ohmage mysql location, user/pass source
mysql_host = ENV['DB_HOST']
mysql_db = ENV['MYSQL_DATABASE']
mysql_user = ENV['MYSQL_USER']
mysql_password = ENV['MYSQL_PASSWORD']
mysql_user_query = if ENV.key? 'MYSQL_USER_QUERY'
                     ENV['MYSQL_USER_QUERY']
                   else
                     'select distinct user.username,user.password from user'
                   end

# all users from this query will be created.
mysql_user_query = 'select distinct user.username,user.password from user'

# flat file db to hold sync password state
daybreak_db_file = "/account_sync.db"

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
      `chown #{u['username']}:#{u['username']} -R /home/#{u['username']}`
    end
    changed_users.each do |u|
      `echo '#{u['username']}:#{u['password']}' | chpasswd -e`
    end
  end
rescue Exception => e # nice error handling, man.
  p "#{Time.now.asctime()}: Sync Error, password sync potentially failed: #{e}"
end

p "#{Time.now.asctime()}: Sync Finished. New Users(#{new_users.count}), Updated Passwords(#{changed_users.count})"
