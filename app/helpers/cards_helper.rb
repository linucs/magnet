module CardsHelper
  include Concerns::Videable

  def card_box_class(card)
    if !card.online?
      'box-default'
    elsif card.pinned?
      'box-danger'
    else
      'box-primary'
    end
  end

  def card_media_tag(card)
    if card.is_video? || card.is_audio?
      case card.content_source
      when 'youtube' then youtube_iframe_tag(youtube_uid(card.media_url))
      when 'vine' then vine_iframe_tag(card.media_url)
      when 'vimeo' then vimeo_iframe_tag(vimeo_uid(card.media_url))
      when 'spotify' then spotify_iframe_tag(card.media_url)
      when 'facebook' then facebook_iframe_tag(card.media_url)
      else
        video_html5_tag(card.media_url)
      end
    elsif card.is_image?
      image_tag(card.media_url, class: 'img-responsive') if card.media_url.present?
    else
      card.embed_code
    end
  end

  def vimeo_iframe_tag(video_uuid, allow_loop = false, auto_play = false)
    url = "http://player.vimeo.com/video/#{video_uuid}?"
    url += "autoplay=#{auto_play ? 1 : 0}&loop=#{allow_loop ? 1 : 0}&api=1&player_id=#{video_uuid}&title=0&byline=0portrait=0"
    content_tag(:iframe, '',
                id: video_uuid,
                class: 'vimeo player embed-responsive-item',
                frameborder: 0,
                src: url)
  end

  def youtube_iframe_tag(video_uuid, auto_play = false)
    url = "http://www.youtube.com/embed/#{video_uuid}?wmode=transparent&enablejsapi=1&autoplay=#{auto_play ? 1 : 0}"
    content_tag(:iframe, '',
                id: video_uuid,
                class: 'youtube player embed-responsive-item',
                src: url,
                allowFullScreen: 'allowfullscreen',
                frameborder: 0)
  end

  def spotify_iframe_tag(uri)
    content_tag(:iframe, '',
                src: "https://embed.spotify.com/?uri=#{uri}&view=coverart",
                class: 'spotify player embed-responsive-item',
                allowtransparency: 'true',
                frameborder: 0)
  end

  def video_html5_tag(uri, oid = rand)
    content_tag(:video,
                id: "video-#{oid}",
                class: 'video player embed-responsive-item',
                controls: true,
                allowfullscreen: true) do
      content_tag(:source, nil, src: uri, type: 'video/mp4')
    end
  end

  def instagram_video_iframe_tag(uri)
    content_tag(:iframe, '',
                src: uri + 'embed',
                class: 'instagram player embed-responsive-item',
                allowtransparency: true,
                frameborder: 0,
                scrolling: 'no')
  end

  def vine_iframe_tag(uri)
    content_tag(:iframe, '',
                src: "#{uri}/card",
                class: 'vine player embed-responsive-item',
                allowtransparency: true,
                frameborder: 0)
  end

  def facebook_iframe_tag(uri)
    content_tag(:iframe, '',
                src: uri,
                class: 'facebook player embed-responsive-item',
                allowtransparency: true,
                frameborder: 0)
  end
end
