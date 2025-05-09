class ShopifyCustomerSyncJob < ApplicationJob
  queue_as :default

  # password is required for Shopify customer creation
  def perform(user_id, password, tags = nil)
    user = User.find_by(id: user_id)
    return unless user && user.shopify_customer_id.blank?
    shopify_customer = Shopify::StorefrontService.create_customer(
      email: user.email,
      password: password,
      first_name: user.first_name,
      last_name: user.last_name,
      tags: tags
    )
    if shopify_customer&.id
      user.update(shopify_customer_id: shopify_customer.id)
      Rails.logger.info("Shopify customer sync succeeded for user #{user.email}")
    else
      errors = shopify_customer&.customer_user_errors&.map(&:message)&.join(", ") if shopify_customer&.respond_to?(:customer_user_errors)
      Rails.logger.error("Shopify customer sync failed for user #{user.email}: #{errors}")
      # Optionally: retry or notify admin
    end
  end
end
