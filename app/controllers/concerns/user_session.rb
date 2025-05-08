module UserSession
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :user_signed_in?
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
    current_user.present?
  end

  def require_login
    unless user_signed_in?
      flash[:alert] = "You must be logged in to access this page."
      redirect_to login_path
    end
  end
end
