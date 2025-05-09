# frozen_string_literal: true

require "httparty"

module Mayar
  class PaymentService
    BASE_URL = ENV.fetch("MAYAR_API_BASE_URL", "https://api.mayar.id/v2")
    API_KEY = ENV["MAYAR_API_KEY"]

    def self.create_invoice(name:, email:, mobile:, redirect_url:, description:, expired_at:, items:)
      url = "#{BASE_URL}/invoice/create"
      headers = {
        "Authorization" => "Bearer #{API_KEY}",
        "Content-Type" => "application/json"
      }
      body = {
        name: name,
        email: email,
        mobile: mobile,
        redirectUrl: redirect_url,
        description: description,
        expiredAt: expired_at,
        items: items
      }
      response = HTTParty.post(url, headers: headers, body: body.to_json)
      parsed = response.parsed_response
      Rails.logger.info("Mayar Payment API response: #{parsed.inspect}")
      if response.success?
        parsed
      else
        Rails.logger.error("Mayar Payment API error: #{response.body}")
        nil
      end
    end
  end
end
