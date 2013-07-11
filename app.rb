require 'sinatra'
require 'dotenv'
require 'nestful'
require 'data_mapper'
require 'open-uri'
require_relative 'lib/robotar.rb'

enable :sessions

configure do
	Dotenv.load if settings.development?
	DataMapper.setup(:default, ENV['DATABASE_URL'])
	DataMapper.finalize
	DataMapper.auto_upgrade!
end

before do
	@mixup_ad = Nestful.get("http://serve.mixup.hapnic.com/#{ENV['MXIT_APP_NAME']}").body
end

get '/' do
	create_user unless get_user
	session[:robotar] = nil
	session[:robotar] = "http://robohash.org/#{(0...50).map{ ('a'..'z').to_a[rand(26)] }.join}.png"
	erb :home
end

get '/avatars/save' do
	redirect to MxitAPI.request_access('avatar/write', "http://#{request.host}:#{request.port}/avatars/set")
end

get '/avatars/set' do
	file = open(session[:robotar])
	MxitAPI.set_avatar(params[:code], file, "http://#{request.host}:#{request.port}/avatars/set")
	erb :robotar
end

get '/about' do
	erb "Robotar is a small Mxit app for creating unique robot avatars. Credits go to <a href='http://robohash.org/'>Robohash</a> for the robots. <a href='/'>Back</a>"
end

helpers do
	def get_user
		mxit_user = MxitUser.new(request.env)
		User.first(:mxit_user_id => mxit_user.user_id)
	end
	def create_user
		mxit_user = MxitUser.new(request.env)
		User.create(:mxit_user_id => mxit_user.user_id, :date_joined => Time.now)
	end
	def protected!
	    unless authorized?
	      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
	      throw(:halt, [401, "Not authorized\n"])
	    end
  	end
  	def authorized?
	    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
	    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', ENV['USER_SECRET']]
  	end
end