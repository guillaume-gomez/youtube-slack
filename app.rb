require 'sinatra'
require 'byebug'
require 'httparty'

require 'slack-ruby-client'

def format_message(channel_id, risitas_url, user_id, text, choosed = false ,ts = nil, token = nil)
  actions = !choosed ?
    [
      {
        name: 'select_risitas',
        text: 'Previous',
        value: 'previous',
        type: 'button',
      },
      {
        name: 'select_risitas',
        text: 'Choose',
        value: 'choose',
        type: 'button',
      },
      {
        name: 'select_risitas',
        text: 'Next',
        value: 'next',
        type: 'button',
      },
      {
        name: 'select_risitas',
        text: 'Cancel',
        value: 'cancel',
        type: 'button',
        style: 'danger',
      },
    ] :
    []


  pretext = !choosed ? "Est ce le risitas que tu voulais ?\n" : ""
  title = !choosed ? "" : text
  title_link = !choosed ? "" : risitas_url
  as_user = !choosed
  
  username = nil
  icon_url = nil
  if choosed
    user_informations = SlackUser.find_by(slack_id: user_id)
    username = user_informations.display_name
    icon_url = user_informations.image_original
  end

  attachments = [{
    pretext: pretext,
    title: title,
    title_link: title_link,
    image_url: risitas_url,
    callback_id: 'select_risitas',
    actions: actions
  }]

  { 
    attachments: attachments,
    channel: channel_id,
    ts: ts,
    user: user_id,
    replace_original: true,
    response_type: "in_channel",
    as_user: as_user,
    username: username,
    icon_url: icon_url
  }
end

def delete_message(response_url)
  options  = {
    body: { replace_original: true, response_type: "in_channel", delete_original: true, text: "" }.to_json,
    headers: { 'Content-Type' => 'application/json' }
  }
  HTTParty.post(response_url, options)
end


class YoutubeSlack < Sinatra::Base

  def initialize(app = nil)
    super(app)
    $last_search = nil
    $last_results  = []
    $current_index = 0
    $teams = {}
  end

  post '/slack/commands' do
    $teams = SlackClient.new

    team_id = params["team_id"]
    token = params["token"]
    
    channel_id = params["channel_id"]
    
    user_id = params["user_id"] 
    user_name = params["user_name"]
    text = params["text"]
    response_url = params["response_url"]
    risitas_urls = [] # result to add

    if risitas_urls.count == 0
      $teams.client().chat_postMessage(user: user_id, channel: channel_id, text: "No results _:(_ for this research ' *#{text}* '")
      return ""
    end
    
    $last_results = risitas_urls
    $last_search = text
    $current_index = 0
    $teams.client().chat_postEphemeral(format_message(channel_id, $last_results[$current_index], user_id, text))
    ""
  end

  post '/slack/after_button' do
    payload = JSON.parse(params["payload"])
    channel_id = payload["channel"]["id"]
    user_id = payload["user"]["id"]
    ts = payload["message_ts"]
    team_id = payload["team"]["id"]
    action = payload["actions"].first
    action_name = action["name"]
    action_value = action["value"]
    token = action["token"]
    response_url = payload["response_url"]

    text = $last_search

    choosed = false
    if action_value == "choose"
      choosed = true
      
      # first delete the ephemeral message, then create the final message with the choosed link
      delete_message(response_url)

      $teams.client().chat_postMessage(format_message(channel_id, $last_results[$current_index], user_id, text, choosed ,ts))
      return ""
    elsif action_value == "previous"
      $current_index = $current_index - 1
    elsif action_value == "next"
      $current_index = $current_index + 1
    elsif action_value == "cancel"
      delete_message(response_url)
      return ""
    end

    # update ephemeral messages
    options  = {
      body: format_message(channel_id, $last_results[$current_index], user_id, text, choosed ,ts).to_json,
      headers: { 'Content-Type' => 'application/json' }
    }
    HTTParty.post(response_url, options)
    ""
  end

end