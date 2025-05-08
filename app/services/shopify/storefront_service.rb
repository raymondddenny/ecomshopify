# frozen_string_literal: true

require 'graphql/client'
require 'graphql/client/http'

module Shopify
  # Service for interacting with Shopify Storefront API
  class StorefrontService
    # Configure the HTTP connection to the Shopify Storefront API
    HTTP = GraphQL::Client::HTTP.new("https://#{ENV.fetch('SHOPIFY_SHOP_DOMAIN')}/api/2023-10/graphql.json") do
      def headers(_context)
        {
          "X-Shopify-Storefront-Access-Token" => ENV.fetch('SHOPIFY_STOREFRONT_ACCESS_TOKEN'),
          "Content-Type" => "application/json"
        }
      end
    end

    # Load the schema (in production, cache this)
    Schema = GraphQL::Client.load_schema(HTTP)
    Client = GraphQL::Client.new(schema: Schema, execute: HTTP)

    # Example query: Fetch products
    ProductsQuery = Client.parse <<-'GRAPHQL'
      query($first: Int!) {
        products(first: $first) {
          edges {
            node {
              id
              title
              handle
              description
              images(first: 1) { edges { node { url } } }
              priceRange { minVariantPrice { amount currencyCode } }
            }
          }
        }
      }
    GRAPHQL

    def self.fetch_products(first: 10)
      response = Client.query(ProductsQuery, variables: { first: first })
      if response.errors.any?
        Rails.logger.error("Shopify Storefront API errors: #{response.errors.messages}")
        return []
      end
      response.data.products.edges.map(&:node)
    end
  end
end
