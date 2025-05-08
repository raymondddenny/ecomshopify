# frozen_string_literal: true

require "graphql/client"
require "graphql/client/http"

module Shopify
  # Service for interacting with Shopify Storefront API
  class StorefrontService
    # Configure the HTTP connection to the Shopify Storefront API
    HTTP = GraphQL::Client::HTTP.new("https://#{ENV.fetch('SHOPIFY_SHOP_DOMAIN')}/api/2023-10/graphql.json") do
      def headers(_context)
        {
          "X-Shopify-Storefront-Access-Token" => ENV.fetch("SHOPIFY_STOREFRONT_ACCESS_TOKEN"),
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
              tags
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

    # Fetch a single product by handle
    ProductByHandleQuery = Client.parse <<-'GRAPHQL'
      query($handle: String!) {
        productByHandle(handle: $handle) {
          id
          title
          handle
          descriptionHtml
          tags
          images(first: 5) { edges { node { url altText } } }
          priceRange { minVariantPrice { amount currencyCode } }
        }
      }
    GRAPHQL

    def self.fetch_product_by_handle(handle)
      response = Client.query(ProductByHandleQuery, variables: { handle: handle })
      if response.errors.any?
        Rails.logger.error("Shopify Storefront API errors: #{response.errors.messages}")
        return nil
      end
      response.data.product_by_handle
    end
    # Fetch related/recommended products for a given product ID
    ProductRecommendationsQuery = Client.parse <<-'GRAPHQL'
      query($productId: ID!) {
        productRecommendations(productId: $productId) {
          id
          title
          handle
          description
          tags
          images(first: 1) { edges { node { url altText } } }
          priceRange { minVariantPrice { amount currencyCode } }
        }
      }
    GRAPHQL

    def self.fetch_product_recommendations(product_id)
      response = Client.query(ProductRecommendationsQuery, variables: { productId: product_id })
      Rails.logger.info("Shopify Storefront API: productRecommendations response for #{product_id}: #{response.data.product_recommendations.inspect}")
      if response.errors.any?
        Rails.logger.error("Shopify Storefront API errors: #{response.errors.messages}")
        return []
      end
      response.data.product_recommendations
    end
  end
end
