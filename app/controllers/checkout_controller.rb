class CheckoutController < ApplicationController
  def new
    # Optionally: prefill from user/cart session
  end

  def create
    # Extract checkout params
    buyer_identity = {
      email: params[:email],
      phone: params[:phone],
      deliveryAddressPreferences: [
        {
          deliveryAddress: {
            address1: params[:address1],
            city: params[:city],
            province: params[:province],
            country: params[:country],
            zip: params[:postal_code],
            firstName: params[:full_name].to_s.split(" ").first,
            lastName: params[:full_name].to_s.split(" ")[1..]&.join(" ") || ""
          }
        }
      ]
    }
    # TODO: Get cart_id from session or params
    cart_id = session[:cart_id]
    if cart_id.blank?
      redirect_to cart_path, alert: "Cart not found." and return
    end

    # Call service to update cart buyer identity via Storefront API
    result = Shopify::StorefrontService.update_cart_buyer_identity(cart_id, buyer_identity)

    if result[:success]
      # Proceed to payment (Mayar.id integration placeholder)
      redirect_to checkout_create_path, notice: "Checkout info saved. Proceed to payment."
    else
      flash.now[:alert] = result[:error] || "Could not update checkout info."
      render :new, status: :unprocessable_entity
    end
  end
end
