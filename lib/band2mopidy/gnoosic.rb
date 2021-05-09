# lib/gnoosic.rb

require "nokogiri"

class Band2Mopidy::Gnoosic
  LIKE = "I like it"
  DO_NOT_LIKE = "I don't like it"
  DO_NOT_KNOW = "I don't know"

  attr_accessor :faves, :history, :cookie

  def initialize
    @faves = []
    @history = []
    @cookies = HTTParty::CookieHash.new
  end

  def submit_faves(fave01, fave02, fave03)
    data = {
      skip: "1",
      Fave01: fave01,
      Fave02: fave02,
      Fave03: fave03,
    }

    @faves = [fave01, fave02, fave03]
    @history = []
    @cookies = HTTParty::CookieHash.new

    response = HTTParty.post(url("faves.php"), { body: data, follow_redirects: false })
    raise unless response.code == 302
    response.get_fields("Set-Cookie").each { |c| @cookies.add_cookies(c) }
    redirect = response.headers["location"]

    response = HTTParty.post(url(redirect), { body: data, headers: headers })

    push_history response, :first
  end

  def submit_response(kind)
    supp_id = self.supp_id
    raise "Haven't submitted yet" unless supp_id

    text = case kind
           when :like
             LIKE
           when :do_not_like
             DO_NOT_LIKE
           when :do_not_know
             DO_NOT_KNOW
           else
             raise "Unknown response kind"
           end

    data = {
      SuppID: supp_id.to_s,
      RateN01: text
    }

    response = HTTParty.post(url("artist/"), { body: data, headers: headers })

    push_history response, kind
  end

  def found_artists
    @history.map { |h| h[:artist_name] }.compact
  end

  private

  def url(location)
    "https://www.gnoosic.com/#{location}"
  end

  def headers
    {
      "Cookie" => @cookies.to_cookie_string
    }
  end

  def cookie
    @history.last&.[](:cookie)
  end

  def supp_id
    @history.last&.[](:supp_id)
  end

  def latest_artist_name
    @history.last&.[](:artist_name)
  end

  def push_history(response, kind)
    page = Nokogiri::HTML.parse(response.to_s)
    input = page.css("input[name='SuppID']")[0]
    raise response.to_s unless input
    supp_id = input.attr("value").to_i

    artist = page.css("a#result")[0]
    entry = if artist
              {supp_id: supp_id, artist_name: artist.text}
            else
              {supp_id: supp_id, artist_name: nil}
            end

    @history << entry

    if !artist
      submit_response(:do_not_like)
    else
      entry
    end
  end
end
