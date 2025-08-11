require "test_helper"

class Api::V1::CamerasControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_cameras_index_url
    assert_response :success
  end

  test "should get show" do
    get api_v1_cameras_show_url
    assert_response :success
  end

  test "should get create" do
    get api_v1_cameras_create_url
    assert_response :success
  end

  test "should get update" do
    get api_v1_cameras_update_url
    assert_response :success
  end

  test "should get destroy" do
    get api_v1_cameras_destroy_url
    assert_response :success
  end

  test "should get stats" do
    get api_v1_cameras_stats_url
    assert_response :success
  end
end
