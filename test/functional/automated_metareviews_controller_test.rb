require 'test_helper'

class AutomatedMetareviewsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:automated_metareviews)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create automated_metareview" do
    assert_difference('AutomatedMetareview.count') do
      post :create, :automated_metareview => { }
    end

    assert_redirected_to automated_metareview_path(assigns(:automated_metareview))
  end

  test "should show automated_metareview" do
    get :show, :id => automated_metareviews(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => automated_metareviews(:one).to_param
    assert_response :success
  end

  test "should update automated_metareview" do
    put :update, :id => automated_metareviews(:one).to_param, :automated_metareview => { }
    assert_redirected_to automated_metareview_path(assigns(:automated_metareview))
  end

  test "should destroy automated_metareview" do
    assert_difference('AutomatedMetareview.count', -1) do
      delete :destroy, :id => automated_metareviews(:one).to_param
    end

    assert_redirected_to automated_metareviews_path
  end
end
