class CartController < ApplicationController
  include CartSession

  def add
    product_id = params[:product_id]
    quantity = params[:quantity].to_i
    quantity = 1 if quantity < 1
    add_to_cart(product_id, quantity)
    flash[:notice] = "Added to cart."
    redirect_back fallback_location: products_path
  end

  def buy_now
    product_id = params[:product_id]
    quantity = params[:quantity].to_i
    quantity = 1 if quantity < 1
    session[:buy_now] = { product_id: product_id, quantity: quantity }
    flash[:notice] = "Proceeding to checkout."
    redirect_to checkout_path
  end

  def checkout
    # Placeholder for checkout logic
    # You can access session[:buy_now] here
  end

  # For upcoming cart page
  def show
    @cart_items = cart_items
    # You will fetch product info for these IDs in the view
  end

  def update
    product_id = params[:product_id]
    quantity = params[:quantity].to_i
    set_cart_quantity(product_id, quantity)
    flash[:notice] = "Cart updated."
    redirect_to cart_path
  end

  def remove
    product_id = params[:product_id]
    remove_from_cart(product_id)
    flash[:notice] = "Item removed from cart."
    redirect_to cart_path
  end

  def clear
    clear_cart
    flash[:notice] = "Cart cleared."
    redirect_to cart_path
  end
end
