module ApplicationHelper
  def alert(msg, options = {})
    content_tag(:div, msg, class: "alert alert-#{options[:level] || 'info'} #{options[:class]}")
  end

  def theme_class
    if devise_controller? && !user_signed_in?
      'login-page'
    else
      'skin-blue'
    end
  end
end
