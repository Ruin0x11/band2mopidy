# lib/discogs.rb
require "discogs"
require "nokogiri"
require "httparty"

class Band2Mopidy::Discogs
  attr_reader :client

  def initialize(app_name, user_token)
    @client = Discogs::Wrapper.new(app_name, user_token: user_token)
  end

  def search_artists(name)
    name = name.downcase
    page = 1
    final = []

    loop do
      results = @client.search(name, type: "artist", page: page)["results"]
      break if results.nil?

      page = page + 1

      results = results.each_with_index.filter do |r, i|
        artist = @client.get_artist(r["id"])
        titles = (artist["namevariations"] || []).append(r["title"]).map(&:downcase)
        titles.any? { |title| i == 0 || title == name || title.match?(/^#{name} \([0-9]+\)$/) }
      end.map { |r, i| r }

      final.concat(results)

      break if page > 5
    end

    final.take(20).map do |a|
      artist_id = a["id"]
      release_count = @client.get_artist_releases(artist_id, per_page: 200)["pagination"]["items"]

      artist = @client.get_artist(artist_id)
      name = a["title"]
      desc = artist["profile"]
      urls = artist["urls"]
      {
        id: artist_id,
        release_count: release_count,
        name: name,
        desc: desc,
        urls: urls,
        video_ids: get_video_ids(artist_id)
      }
    end.sort { |a, b| -(a[:release_count]<=>b[:release_count]) }
  end

  private

  def get_video_ids(artist_id)
    response = HTTParty.get("https://www.discogs.com/artist/#{artist_id}")
    page = Nokogiri::HTML.parse(response.to_s)
    player = page.css("div#youtube_player_placeholder")[0]
    if player
      ids = player.attr("data-video-ids")
      ids.split ","
    else
      []
    end
  end
end
