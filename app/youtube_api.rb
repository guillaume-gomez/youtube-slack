require 'uri'
require 'httparty'

class YoutubeApi
  include HTTParty

  base_uri "https://www.googleapis.com/youtube/v3"

  attr_accessor :search, :results

  def initialize(search, results)
    self.search = search
    self.results = results
  end

 def self.find(search)
    response = get("/search?part=snippet&q=#{search}&key=#{ENV['YOUTUBE_API']}")
    if response.success?
      JSON.parse(response)
      # todo
      full_urls << []
      self.new(search, full_urls)
      full_urls
    else
      # this just raises the net/http response that was raised
      []
    end
  end
end
