require File.dirname(__FILE__) + '/../test_helper'

class EmployeesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:employees)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_employee
    assert_difference('Employee.count') do
      post :create, :employee => { }
    end

    assert_redirected_to employee_path(assigns(:employee))
  end

  def test_should_show_employee
    get :show, :id => employees(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => employees(:one).id
    assert_response :success
  end

  def test_should_update_employee
    put :update, :id => employees(:one).id, :employee => { }
    assert_redirected_to employee_path(assigns(:employee))
  end

  def test_should_destroy_employee
    assert_difference('Employee.count', -1) do
      delete :destroy, :id => employees(:one).id
    end

    assert_redirected_to employees_path
  end
end
