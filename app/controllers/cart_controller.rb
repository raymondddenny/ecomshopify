class CartController < ApplicationController
  include CartSession

  def checkout_success
    cart_id = session[:shopify_cart_id]
    if cart_id.present?
      cart = Shopify::StorefrontService.fetch_cart(cart_id)
      if cart && cart.lines.edges.any?
        # Build Shopify order payload from current cart
        line_items = cart.lines.edges.map do |edge|
          graphql_id = edge.node.merchandise.id.to_s
          numeric_id = graphql_id.split("/").last
          {
            variant_id: numeric_id,
            quantity: edge.node.quantity
          }
        end
        # For customer info, fallback to session or use dummy/test data if not stored
        # You should store these in session at checkout initiation for real deployment
        customer_email = session[:checkout_email] || "test@example.com"
        customer_name = session[:checkout_full_name] || "Test User"
        address1 = session[:checkout_address1] || ""
        city = session[:checkout_city] || ""
        province = session[:checkout_province] || ""
        country = session[:checkout_country] || ""
        postal_code = session[:checkout_postal_code] || ""
        phone = session[:checkout_phone] || ""
        order_payload = {
          order: {
            email: customer_email,
            line_items: line_items,
            financial_status: "paid",
            shipping_address: {
              address1: address1,
              city: city,
              province: province,
              country: country,
              zip: postal_code,
              name: customer_name,
              phone: phone
            }
          }
        }
        order = Shopify::AdminService.create_order(order_payload)
        if order
          # Clear Shopify cart
          line_ids = cart.lines.edges.map { |edge| edge.node.id }
          Shopify::StorefrontService.remove_cart_lines(cart_id: cart_id, line_ids: line_ids) if line_ids.any?
          # Clear session
          session[:shopify_cart_id] = nil
          session[:checkout_email] = nil
          session[:checkout_full_name] = nil
          session[:checkout_address1] = nil
          session[:checkout_city] = nil
          session[:checkout_province] = nil
          session[:checkout_country] = nil
          session[:checkout_postal_code] = nil
          session[:checkout_phone] = nil
          flash[:notice] = "Order created in Shopify and cart cleared."
        else
          flash[:alert] = "Order creation failed. Please contact support."
        end
      else
        # Cart is empty or not found
        session[:shopify_cart_id] = nil
        flash[:alert] = "Cart is empty or not found."
      end
    else
      flash[:alert] = "No cart found for checkout."
    end
    render :checkout_success
  end

  def add
    variant_id = params[:variant_id] || params[:product_id] # fallback for now
    quantity = params[:quantity].to_i
    quantity = 1 if quantity < 1

    if session[:shopify_cart_id].present?
      result = Shopify::StorefrontService.add_lines_to_cart(
        cart_id: session[:shopify_cart_id],
        variant_id: variant_id,
        quantity: quantity
      )
    else
      result = Shopify::StorefrontService.create_cart(
        variant_id: variant_id,
        quantity: quantity
      )
      session[:shopify_cart_id] = result[:cart_id] if result
    end

    if result
      flash[:notice] = "Added to cart."
    else
      flash[:alert] = "There was a problem adding to cart."
    end
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
    if request.post?
      # Extract checkout params
      # Auto-format phone to E.164 for Indonesia
      phone = params[:phone].to_s.strip
      if phone.start_with?("0") && params[:country].to_s.downcase.include?("indonesia")
        phone = "+62" + phone[1..]
      end
      buyer_identity = {
        email: params[:email],
        phone: phone,
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
      cart_id = session[:shopify_cart_id]
      if cart_id.blank?
        redirect_to cart_path, alert: "Cart not found." and return
      end
      cart = Shopify::StorefrontService.fetch_cart(cart_id)
      if cart.nil?
        redirect_to cart_path, alert: "Cart not found." and return
      end

      # Feature flag: bypass Mayar payment, create Shopify order directly
      use_direct_shopify_order = false # set to false to re-enable Mayar payment

      if use_direct_shopify_order
        # Build Shopify order payload from cart
        line_items = cart.lines.edges.map do |edge|
          {
            variant_id: edge.node.merchandise.id.split("/").last,
            quantity: edge.node.quantity
          }
        end
        order_payload = {
          order: {
            email: params[:email],
            line_items: line_items,
            shipping_address: {
              address1: params[:address1],
              city: params[:city],
              province: params[:province],
              country: params[:country],
              zip: params[:postal_code],
              first_name: params[:full_name].to_s.split(" ").first,
              last_name: params[:full_name].to_s.split(" ")[1..]&.join(" ") || ""
            },
            customer: {
              first_name: params[:full_name].to_s.split(" ").first,
              last_name: params[:full_name].to_s.split(" ")[1..]&.join(" ") || "",
              email: params[:email]
            },
            financial_status: "paid"
          }
        }
        shopify_order = Shopify::AdminService.create_order(order_payload)
        if shopify_order
          flash[:notice] = "Order created successfully!"
          redirect_to checkout_success_path and return
        else
          redirect_to cart_path, alert: "Could not create Shopify order. Please try again." and return
        end
      else
        # Build Mayar invoice items from cart
        items = cart.lines.edges.map do |edge|
          {
            quantity: edge.node.quantity,
            rate: edge.node.cost.amount_per_quantity.amount.to_i,
            description: edge.node.merchandise.product.title
          }
        end
        # Compose description
        description = "Order for #{params[:full_name]} (#{cart.lines.edges.size} items)"
        expired_at = 1.day.from_now.iso8601
        payment_response = Mayar::PaymentService.create_invoice(
          name: params[:full_name],
          email: params[:email],
          mobile: phone,
          redirect_url: checkout_success_url,
          description: description,
          expired_at: expired_at,
          items: items
        )
        if payment_response && payment_response["data"]["link"]
          redirect_to payment_response["data"]["link"], allow_other_host: true and return
        else
          redirect_to cart_path, alert: "Could not create payment link. Please try again." and return
        end
      end
      # Call service to update cart buyer identity via Storefront API
      result = Shopify::StorefrontService.update_cart_buyer_identity(cart_id, buyer_identity)
      if result[:success]
        # --- Create Shopify order via Admin API (payment bypassed, status: pending) ---
        cart_id = session[:shopify_cart_id]
        cart = Shopify::StorefrontService.fetch_cart(cart_id)
        if cart
          line_items = cart.lines.edges.map do |edge|
            # Extract numeric variant ID for Admin API
            graphql_id = edge.node.merchandise.id.to_s
            numeric_id = graphql_id.split("/").last
            {
              variant_id: numeric_id,
              quantity: edge.node.quantity
            }
          end
          order_payload = {
            order: {
              email: params[:email],
              line_items: line_items,
              financial_status: "pending",
              shipping_address: {
                address1: params[:address1],
                city: params[:city],
                province: params[:province],
                country: params[:country],
                zip: params[:postal_code],
                name: params[:full_name],
                phone: phone
              }
            }
          }
          order = Shopify::AdminService.create_order(order_payload)
          if order
            flash[:notice] = "Order created in Shopify (pending payment)."
            # Optionally clear cart
            session[:shopify_cart_id] = nil
            redirect_to root_path and return
          else
            flash.now[:alert] = "Order creation failed."
            render :checkout, status: :unprocessable_entity and return
          end
        else
          flash.now[:alert] = "Cart not found for order creation."
          render :checkout, status: :unprocessable_entity and return
        end
      else
        flash.now[:alert] = result[:error] || "Could not update checkout info."
        render :checkout, status: :unprocessable_entity
      end
    else
      render :checkout
    end
  end

  # For upcoming cart page
  before_action :require_login, only: [ :show, :checkout ]

  def show
    if session[:shopify_cart_id].present?
      @cart = Shopify::StorefrontService.fetch_cart(session[:shopify_cart_id])
      if @cart
        @cart_items = @cart.lines.edges.map do |edge|
        line_id = edge.node.id
        variant_id = edge.node.merchandise.id
        product = edge.node.merchandise.product
        quantity = edge.node.quantity
        price = edge.node.cost.amount_per_quantity.amount.to_f
        currency = edge.node.cost.amount_per_quantity.currency_code
        [ line_id, variant_id, quantity, product, price, currency ]
      end
      else
        @cart_items = []
      end
    else
      @cart_items = []
    end
  end

  def update
    line_id = params[:line_id]
    quantity = params[:quantity].to_i
    if session[:shopify_cart_id].present? && line_id.present?
      Shopify::StorefrontService.update_cart_line(
        cart_id: session[:shopify_cart_id],
        line_id: line_id,
        quantity: quantity
      )
    end
    flash[:notice] = "Cart updated."
    redirect_to cart_path
  end

  def remove
    line_id = params[:line_id]
    if session[:shopify_cart_id].present? && line_id.present?
      Shopify::StorefrontService.remove_cart_lines(
        cart_id: session[:shopify_cart_id],
        line_ids: [ line_id ]
      )
    end
    flash[:notice] = "Item removed from cart."
    redirect_to cart_path
  end

  def clear
    if session[:shopify_cart_id].present?
      cart = Shopify::StorefrontService.fetch_cart(session[:shopify_cart_id])
      if cart
        line_ids = cart.lines.edges.map { |edge| edge.node.id }
        Shopify::StorefrontService.remove_cart_lines(
          cart_id: session[:shopify_cart_id],
          line_ids: line_ids
        )
      end
    end
    flash[:notice] = "Cart cleared."
    redirect_to cart_path
  end

  private

  def require_login
    unless session[:user_id] && User.exists?(id: session[:user_id])
      flash[:alert] = "You must be logged in to access the cart or checkout."
      redirect_to login_path
    end
  end
end
