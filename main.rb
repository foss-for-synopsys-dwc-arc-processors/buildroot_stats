require 'rubygems'
require 'data_mapper' # requires all the gems listed above
require 'dm-migrations'

# If you want the logs displayed you have to do this before the call to setup
DataMapper::Logger.new($stdout, :debug)

# An in-memory Sqlite3 connection:
#DataMapper.setup(:default, 'sqlite::memory:')
 
# A Sqlite3 connection to a persistent database

PWD=`pwd`

def setupDatamapper
        DataMapper.setup(:default, "sqlite://#{PWD}db.sqlite")
        Dir["#{PWD}/dbmodel/*.rb"].each {|file| require file }
        DataMapper.finalize
        DataMapper.auto_upgrade!
end
