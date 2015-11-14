require 'test_helper'

class BoardsControllerTest < ActionController::TestCase
  setup do
    @board = boards(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:boards)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create board" do
    assert_difference('Board.count') do
      post :create, board: { category_id: @board.category_id, description: @board.description, image: @board.image, name: @board.name, enabled: @board.enabled, polling_count: @board.polling_count, polling_interval: @board.polling_interval, slug: @board.slug }
    end

    assert_redirected_to board_path(assigns(:board))
  end

  test "should show board" do
    get :show, id: @board
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @board
    assert_response :success
  end

  test "should update board" do
    patch :update, id: @board, board: { category_id: @board.category_id, description: @board.description, image: @board.image, name: @board.name, enabled: @board.enabled, polling_count: @board.polling_count, polling_interval: @board.polling_interval, slug: @board.slug }
    assert_redirected_to board_path(assigns(:board))
  end

  test "should destroy board" do
    assert_difference('Board.count', -1) do
      delete :destroy, id: @board
    end

    assert_redirected_to boards_path
  end
end
