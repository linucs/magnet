json.array! @cards + @ads do |card|
  json.id card.id.to_s
  json.provider_name card.provider_name
  json.external_id card.external_id
  json.content card.content
  json.content_type card.content_type
  json.content_source card.content_source
  json.from card.from
  json.source card.source
  json.location card.location
  json.media_url card.media_url
  json.original_content_url card.original_content_url
  json.media_tag card_media_tag(card)
  json.thumbnail_image_url card.thumbnail_image_url
  json.tags card.tags
  json.label card.label
  json.rating card.rating
  json.profile_url card.profile_url
  json.profile_image_url card.profile_image_url
  json.likes_count card.likes_count
  json.shares_count card.shares_count
  json.cta card.cta
  json.created_at card.created_at
  json.updated_at card.updated_at
  json.polled_at card.polled_at
end
