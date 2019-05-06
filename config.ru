require './app'
require './app/auth'
require './app/list_user_scheduler'

# Initialize the app and create the API (bot) and Auth objects.
run Rack::Cascade.new [YoutubeSlack, ListUserScheduler, Auth]