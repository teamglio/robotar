require 'data_mapper'

class User
	include DataMapper::Resource
		
	property :id, Serial
	property :mxit_user_id, Text
	property :mxit_nickname, Text
	property :date_joined, DateTime
end