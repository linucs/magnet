require 'fileutils'

class UserFileResource < DAV4Rack::FileResource
  def root
    return if user.nil?

    File.join(options[:root].to_s, 'boards', user[:board_id].to_s)
  end

  private

  def authenticate(name, password)
    return if name.blank?

    id, email = name.split('/')
    id = id.to_i
    Rails.logger.info "WebDAV: authenticating <#{email}> for board ##{id}"
    if Board.exists?(id)
      auth = User.find_by(email: email)
      if auth.try(:valid_password?, password) && (auth.admin? || auth.board_ids.include?(id))
        self.user = {
          user_id: auth.id,
          board_id: id
        }
        path = root
        FileUtils.mkdir_p(path) unless Dir.exist?(path)
        Rails.logger.info "WebDAV: granted access to <#{auth.email}> for directory #{path}"
        true
      end
    end
  end
end
