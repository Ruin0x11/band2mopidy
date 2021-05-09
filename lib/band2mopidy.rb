# frozen_string_literal: true

require_relative "band2mopidy/version"

module Band2Mopidy
  class Error < StandardError; end
end

require_relative "band2mopidy/gnoosic"
require_relative "band2mopidy/discogs"
require_relative "band2mopidy/bandcamp"
require_relative "band2mopidy/mpd"
