# lib/mpd.rb

require "ruby-mpd"

class Band2Mopidy::MPD
  attr_reader :client

  def initialize(host, port)
    @client = MPD.new(host, port)
    @client.connect
  end

  def send_bandcamp(album)
    @client.add "bandcamp:#{album}"
  end

  def send_youtube(id)
    @client.add "youtube:video:#{id}"
  end
end
