class PagesController < ApplicationController
  def dashboard
    redirect_to boards_path
  end
end
