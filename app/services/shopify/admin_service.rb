# frozen_string_literal: true

require 'httparty'

module Shopify
  class AdminService
    API_VERSION = '2023-10'
    BASE_URL = "https://#{ENV.fetch('SHOPIFY_SHOP_DOMAIN')}/admin/api/#{API_VERSION}"
    ACCESS_TOKEN = ENV.fetch('SHOPIFY_ADMIN_ACCESS_TOKEN')

    def self.create_order(order_payload)
      url = "#{BASE_URL}/orders.json"
      headers = {
        'Content-Type' => 'application/json',
        'X-Shopify-Access-Token' => ACCESS_TOKEN
      }
      response = HTTParty.post(url, headers: headers, body: order_payload.to_json)
      if response.success?
        response.parsed_response['order']
      else
        Rails.logger.error("Shopify Admin API order creation failed: #{response.body}")
        nil
      end
    end
  end
end
