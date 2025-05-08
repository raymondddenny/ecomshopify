# frozen_string_literal: true

# Concern for managing cart session logic in controllers
module CartSession
  extend ActiveSupport::Concern

  # Returns the cart hash from session, always a Hash with string keys
  def current_cart
    session[:cart] ||= {}
    session[:cart]
  end

  # Adds or updates a product in the cart
  def add_to_cart(product_id, quantity = 1)
    cart = current_cart
    cart[product_id.to_s] ||= 0
    cart[product_id.to_s] += quantity.to_i
    session[:cart] = cart
  end

  # Sets the quantity for a product (removes if quantity < 1)
  def set_cart_quantity(product_id, quantity)
    cart = current_cart
    if quantity.to_i < 1
      cart.delete(product_id.to_s)
    else
      cart[product_id.to_s] = quantity.to_i
    end
    session[:cart] = cart
  end

  # Removes a product from the cart
  def remove_from_cart(product_id)
    cart = current_cart
    cart.delete(product_id.to_s)
    session[:cart] = cart
  end

  # Clears the entire cart
  def clear_cart
    session[:cart] = {}
  end

  # Returns the total number of items (sum of quantities)
  def cart_item_count
    current_cart.values.map(&:to_i).sum
  end

  # Returns an array of [product_id, quantity] pairs
  def cart_items
    current_cart.map { |pid, qty| [pid, qty.to_i] }
  end
end
