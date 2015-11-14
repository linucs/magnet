class PagesController < ApplicationController
  def dashboard
    @boards = current_user.boards.last(8)

    respond_to do |format|
      format.html
    end
  end
end
