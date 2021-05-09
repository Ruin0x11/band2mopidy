# lib/bandcamp.rb
require "nokogiri"
require "httparty"

class Band2Mopidy::Bandcamp
  def initialize()
  end

  def search_artists(name)
    response = HTTParty.get("https://bandcamp.com/search", { query: { "q" => name } })
    page = Nokogiri::HTML.parse(response)
    results = page.css(".result-info")

    results.map do |result|
      type = result.css(".itemtype")[0]&.text&.strip.downcase.to_sym
      heading = result.css(".heading")[0]&.text&.strip
      subhead = result.css(".subhead")[0]&.text&.strip
      url = result.css(".itemurl")[0]&.text&.strip
      genre = result.css(".genre")[0]&.text&.strip

      {
        type: type,
        heading: heading,
        subhead: subhead,
        url: url,
        genre: genre
      }
    end
  end
end
