class ParseVideoUrlService
  # @Note: append more formats if needed below
  FORMATS = {
    youtube: [
      %r{(?:https?://)?youtu\.be/(.+)},
      %r{(?:https?://)?(?:www\.)?youtube\.com/watch\?v=(.*?)(&|#|$)},
      %r{(?:https?://)?(?:www\.)?youtube\.com/embed/(.*?)(\?|$)},
      %r{(?:https?://)?(?:www\.)?youtube\.com/v/(.*?)(#|\?|$)},
      %r{(?:https?://)?(?:www\.)?youtube\.com/user/.*?#\w/\w/\w/\w/(.+)\b}
    ],
    vimeo: [%r{vimeo.*/(\d+)}],
    wistia: [%r{(?:https?://)?(?:www\.)?wistia\.com/medias/(.+)}],
    loom: [%r{(?:https?://)?(?:www\.)?loom\.com/share/(.+)}]
  }.freeze

  def initialize(video_url: nil, platform: nil)
    @video_url = video_url
    @platform = platform
  end

  def execute
    @video_url.strip!
    FORMATS[@platform].find { |format| @video_url =~ format } and Regexp.last_match(1)
  end

  
end