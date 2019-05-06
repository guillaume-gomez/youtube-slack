require 'dotenv/load'
require 'slack-ruby-client'
require '../models/slack_credentials'

# Load Slack app info into a hash called `config` from the environment variables assigned during setup
# See the "Running the app" section of the README for instructions.
SLACK_CONFIG = {
  slack_client_id: ENV['SLACK_CLIENT_ID'],
  slack_api_secret: ENV['SLACK_API_SECRET'],
  slack_redirect_uri: ENV['SLACK_REDIRECT_URI'],
  slack_verification_token: ENV['SLACK_VERIFICATION_TOKEN']
}


class SlackClient
  attr_accessor :client
  # Check to see if the required variables listed above were provided, and raise an exception if any are missing.
  missing_params = SLACK_CONFIG.select { |key, value| value.nil? }
  if missing_params.any?
    error_msg = missing_params.keys.join(", ").upcase
    raise "Missing Slack config variables: #{error_msg}"
  end

  def initialize()
    credentials = SlackCredentials.last
    raise "Missing Slack credentials" if credentials.nil?
    @client = {}
    @client[credentials.team_id] = {
        user_access_token: credentials.confirmation_token,
        bot_user_id: credentials.bot_user_id,
        bot_access_token: credentials.bot_access_token,
        team_id: credentials.team_id
      }
    @client['client'] = create_slack_client(credentials.confirmation_token)
  end

  def client()
    @client['client']
  end

  private
  def create_slack_client(slack_api_secret)
    Slack.configure do |config|
      config.token = slack_api_secret
      fail 'Missing API token' unless config.token
    end
    Slack::Web::Client.new
  end


end