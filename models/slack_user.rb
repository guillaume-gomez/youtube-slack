require 'sinatra/base'
require 'sinatra/activerecord'

require 'slack-ruby-client'


class SlackUser < ActiveRecord::Base

  def self.list_and_save_user(client)
    all_members = []
    client.users_list(presence: true, limit: 10) do |response|
      all_members.concat(response.members)
    end
    all_members.each do |member|
      slack_user =  SlackUser.find_or_create_by(slack_id: member["id"])
      slack_user.update_attributes(
        slack_id: member["id"], 
        team_id:member["team_id"],
        real_name: member["real_name"], 
        display_name: member["profile"]["display_name"],
        first_name: member["profile"]["first_name"],
        last_name:member["profile"]["last_name"],
        email: member["profile"]["email"],
        image_original:member["profile"]["image_original"],
        is_custom_image: member["profile"]["is_custom_image"]
      )
    end
  end
end