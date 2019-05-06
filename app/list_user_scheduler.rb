require 'rubygems'
require 'sinatra'
require 'rufus/scheduler'
require '../models/slack_user'

class ListUserScheduler < Sinatra::Base
  scheduler = Rufus::Scheduler.new

  scheduler.every '1d' do
    slack_client = SlackClient.new
    SlackUser.list_and_save_user(slack_client.client())
  end

end