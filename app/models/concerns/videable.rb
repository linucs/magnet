module Concerns
  module Videable
    def vimeo_uid(url)
      url.split('/').last
    end

    def youtube_uid(url)
      regexs = ['v=', 'youtu.be\/', 'embed\/', 'v\/']
      regexs.each do |regex|
        a = url.gsub(/.*#{regex}([^&]+).*$/i, '\1') if url =~ /#{regex}/
        begin
          return a.split('#').first
        rescue
          nil
        end
      end
      nil
    end

    def facebook_uid(url)
      regexs = ['v=', 'v\/']
      regexs.each do |regex|
        return url.gsub(/.*#{regex}([^&]+).*$/i, '\1') if url =~ /#{regex}/
      end
      nil
    end

    def spotify_uid(url)
      regexs = ['track\/']
      regexs.each do |regex|
        return url.gsub(/.*#{regex}([^&]+).*$/i, '\1') if url =~ /#{regex}/
      end
      nil
    end

    def vine_uid(url)
      regexs = ['v\/']
      regexs.each do |regex|
        return url.gsub(/.*#{regex}([^\/&]+).*$/i, '\1') if url =~ /#{regex}/
      end
      nil
    end

    def media_uid(source, uri)
      case source.to_s
      when 'youtube' then youtube_uid(uri)
      when 'vimeo' then vimeo_uid(uri)
      when 'vine' then vine_uid(uri)
      when 'spotify' then spotify_uid(uri)
      when 'facebook' then facebook_uid(uri)
      end
    end

    def resolve_thumbnail_url(source, uri)
      case source.to_s
      when 'youtube'
        # vuid = "#{self.youtube_uid(uri)}".split("?").first.split("#").first
        # "http://img.youtube.com/vi/#{vuid}/0.jpg"
        VideoInfo.new(uri).thumbnail_medium
      when 'vimeo'
        # Vimeo::Simple::Video.info(self.vimeo_uid(uri)).parsed_response[0]["thumbnail_large"]
        VideoInfo.new(uri).thumbnail_medium
      when 'vine'
        begin
          Mechanize.new.get(uri).at("meta[property='twitter:image']").attributes['content'].value
        rescue
          Mechanize.new.get("https://vine.co/v/#{vine_uid(uri)}").at("meta[property='twitter:image']").attributes['content'].value
        end
      when 'spotify'
        client = Faraday.new(url: 'https://embed.spotify.com')
        response = client.get("/oembed/?url=spotify:track:#{spotify_uid(uri)}")
        JSON.parse(response.body)['thumbnail_url'] if response.success?
      else
        uri
      end
    rescue
      nil
    end
  end
end
