class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      # Prepare tags for Shopify
      tags = params[:user][:tags].to_s.split(',').map(&:strip).reject(&:blank?).join(', ')
      shopify_customer = Shopify::StorefrontService.create_customer(
        email: @user.email,
        password: params[:user][:password],
        first_name: @user.first_name,
        last_name: @user.last_name,
        tags: tags.presence
      )
      if shopify_customer&.id
        @user.update(shopify_customer_id: shopify_customer.id)
      else
        errors = shopify_customer&.customer_user_errors&.map(&:message)&.join(', ') if shopify_customer&.respond_to?(:customer_user_errors)
        # Schedule background job for retry
        ShopifyCustomerSyncJob.perform_later(@user.id, params[:user][:password], tags.presence)
        flash[:alert] = "Account created locally, but failed to create Shopify customer. #{errors || 'Will retry in background.'}"
      end
      session[:user_id] = @user.id
      flash[:notice] = "Welcome! You are now signed up."
      redirect_to root_path
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
  end
end
