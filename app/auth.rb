require 'dotenv/load'
require 'byebug'

require 'sinatra/base'
require 'sinatra/activerecord'

require 'slack-ruby-client'

require './slack_client'
require './environments'

# Set the OAuth scope of your bot. We're just using `bot` for this demo, as it has access to
# all the things we'll need to access. See: https://api.slack.com/docs/oauth-scopes for more info.
BOT_SCOPE = 'bot'

# Slack uses OAuth for user authentication. This auth process is performed by exchanging a set of
# keys and tokens between Slack's servers and yours. This process allows the authorizing user to confirm
# that they want to grant our bot access to their team.
# See https://api.slack.com/docs/oauth for more information.
class Auth < Sinatra::Base
  # This is the HTML markup for our "Add to Slack" button.
  # Note that we pass the `client_id`, `scope` and "redirect_uri" parameters specific to our application's configs.
  add_to_slack_button = %(
    <a href=\"https://slack.com/oauth/authorize?scope=#{BOT_SCOPE}&client_id=#{SLACK_CONFIG[:slack_client_id]}&redirect_uri=#{SLACK_CONFIG[:redirect_uri]}\">
      <img alt=\"Add to Slack\" height=\"40\" width=\"139\" src=\"https://platform.slack-edge.com/img/add_to_slack.png\"/>
    </a>
  )

  # If a user tries to access the index page, redirect them to the auth start page
  get '/' do
    redirect '/begin_auth'
  end

  # OAuth Step 1: Show the "Add to Slack" button, which links to Slack's auth request page.
  # This page shows the user what our app would like to access and what bot user we'd like to create for their team.
  get '/begin_auth' do
    status 200
    body add_to_slack_button
  end

  # OAuth Step 2: The user has told Slack that they want to authorize our app to use their account, so
  # Slack sends us a code which we can use to request a token for the user's account.
  get '/finish_auth' do
    client = Slack::Web::Client.new
    # OAuth Step 3: Success or failure
    begin
      response = client.oauth_access(
        {
          client_id: SLACK_CONFIG[:slack_client_id],
          client_secret: SLACK_CONFIG[:slack_api_secret],
          redirect_uri: SLACK_CONFIG[:slack_redirect_uri],
          code: params[:code] # (This is the OAuth code mentioned above)
        }
      )
      credentials = SlackCredentials.where("created_at < ?", 6.months.ago).first_or_create
      credentials.update_attributes({
        confirmation_token: response['access_token'],
        bot_user_id: response['bot']['bot_user_id'],
        bot_access_token: response['bot']['bot_access_token'],
        team_id: response['team_id'],
        confirmation_token_date: DateTime.now
      })
      # Success:
      # Yay! Auth succeeded! Let's store the tokens and create a Slack client to use in our Events handlers.
      # The tokens we receive are used for accessing the Web API, but this process also creates the Team's bot user and
      # authorizes the app to access the Team's Events.
      puts response
      # Be sure to let the user know that auth succeeded.
      status 200
      body "Yay! Auth succeeded! You're awesome!"
    rescue Slack::Web::Api::Error => e
      # Failure:
      # D'oh! Let the user know that something went wrong and output the error message returned by the Slack client.
      status 403
      body "Auth failed! Reason: #{e.message}<br/>#{add_to_slack_button}"
    end
  end
end