require 'uri'
require 'httparty'

class YoutubeApi
  include HTTParty

  base_uri "https://www.googleapis.com/youtube/v3/search"

  attr_accessor :search, :results

  def initialize(search, results)
    self.search = search
    self.results = results
  end

  def self.find(search)
    # todo 
  end
end