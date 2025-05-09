class MayarWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  # POST /mayar_webhooks/payment
  def payment
    # Verify webhook token
    provided_token = request.headers['X-Mayar-Signature'] || params[:token]
    unless ActiveSupport::SecurityUtils.secure_compare(provided_token.to_s, ENV['MAYAR_WEBHOOK_TOKEN'].to_s)
      Rails.logger.warn("Mayar webhook: invalid signature")
      head :unauthorized and return
    end

    payload = request.request_parameters.presence || JSON.parse(request.body.read)
    status = payload['status']
    external_id = payload['external_id']
    customer_email = payload['customer_email']
    Rails.logger.info("Mayar webhook received: status=#{status}, external_id=#{external_id}")

    if status == 'PAID' && external_id.present?
      # Fetch cart and customer info
      cart = Shopify::StorefrontService.fetch_cart(external_id)
      if cart
        line_items = cart.lines.edges.map do |edge|
          graphql_id = edge.node.merchandise.id.to_s
          numeric_id = graphql_id.split("/").last
          {
            variant_id: numeric_id,
            quantity: edge.node.quantity
          }
        end
        order_payload = {
          line_items: line_items,
          customer: {
            email: customer_email
          },
          financial_status: 'paid',
          tags: 'mayar.id'
        }
        order = Shopify::AdminService.create_order(order_payload)
        if order
          Rails.logger.info("Shopify order created for cart #{external_id}")
          head :ok
        else
          Rails.logger.error("Failed to create Shopify order for cart #{external_id}")
          head :internal_server_error
        end
      else
        Rails.logger.error("Cart not found for Mayar webhook external_id=#{external_id}")
        head :not_found
      end
    else
      Rails.logger.warn("Mayar webhook: status not PAID or missing external_id")
      head :ok
    end
  rescue => e
    Rails.logger.error("Mayar webhook error: #{e.message}")
    head :internal_server_error
  end
end
