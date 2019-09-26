require 'uri'
require 'httparty'
require "byebug"

class YoutubeApi
  include HTTParty

  base_uri "https://www.googleapis.com/youtube/v3"

  attr_accessor :search, :results

  def initialize(search, results)
    self.search = search
    self.results = results
  end

 def self.find(search)
    response = get("/search?maxResults=50&order=relevance&part=snippet&q=#{search}&key=#{ENV['YOUTUBE_API']}")
    full_urls = []
    if response.success?
      full_urls << JSON.parse(response.body)["items"].map { |item| item["id"]["videoId"] }
      self.new(search, full_urls)
      full_urls
    else
      # this just raises the net/http response that was raised
      []
    end
  end
end
