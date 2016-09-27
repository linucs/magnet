module ApplicationHelper
  def alert(msg, options = {})
    content_tag(:div, msg, class: "alert alert-#{options[:level] || 'info'} #{options[:class]}")
  end

  def theme_class
    if devise_controller? && !user_signed_in?
      'login-page'
    else
      "pace-supported skin-blue-light #{action_name == 'show' ? 'sidebar-collapse' : nil}"
    end
  end

  def omniauth_authorize_path(resource, provider)
    send("#{resource}_#{provider}_omniauth_authorize_path")
  end
end
