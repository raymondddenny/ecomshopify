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
          options {
            name
            values
          }
          variants(first: 50) {
            edges {
              node {
                id
                title
                availableForSale
                selectedOptions {
                  name
                  value
                }
              }
            }
          }
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

    # Fetch multiple products by their IDs in a single request
    NodesQuery = Client.parse <<-'GRAPHQL'
      query($ids: [ID!]!) {
        nodes(ids: $ids) {
          ... on Product {
            id
            title
            handle
            description
            descriptionHtml
            tags
            images(first: 1) { edges { node { url altText } } }
            priceRange { minVariantPrice { amount currencyCode } }
            variants(first: 10) {
              edges {
                node {
                  id
                  title
                  price { amount currencyCode }
                  quantityAvailable
                }
              }
            }
          }
        }
      }
    GRAPHQL

    def self.fetch_products_by_ids(product_ids)
      return [] if product_ids.empty?

      response = Client.query(NodesQuery, variables: { ids: product_ids })
      if response.errors.any?
        Rails.logger.error("Shopify Storefront API errors fetching products by IDs: #{response.errors.messages}")
        return []
      end

      # Filter out any nil nodes (in case some IDs were invalid)
      response.data.nodes.compact
    end

    # Fetch a single product by ID
    def self.fetch_product_by_id(product_id)
      # Use the same nodes query but with a single ID
      products = fetch_products_by_ids([ product_id ])
      products.first
    end
    # Create a customer in Shopify Storefront API
    CreateCustomerMutation = Client.parse <<-'GRAPHQL'
      mutation($input: CustomerCreateInput!) {
        customerCreate(input: $input) {
          customer {
            id
            email
            firstName
            lastName
          }
          customerUserErrors {
            code
            field
            message
          }
        }
      }
    GRAPHQL

    def self.create_customer(email:, password:, first_name: nil, last_name: nil, tags: nil)
      input = {
        email: email,
        password: password,
        firstName: first_name,
        lastName: last_name
      }.compact
      response = Client.query(CreateCustomerMutation, variables: { input: input })

      # Defensive: handle nil data
      if response.data.nil?
        Rails.logger.error("Shopify Storefront API returned nil data: #{response.errors.messages}")
        return nil
      end

      customer_create = response.data.customer_create
      if customer_create.nil?
        Rails.logger.error("Shopify Storefront API: customer_create is nil. Response data: #{response.data.inspect}, errors: #{response.errors.messages}")
        return nil
      end
      if response.errors.any? || customer_create.customer_user_errors.any?
        Rails.logger.error("Shopify Storefront API customerCreate errors: #{response.errors.messages} #{customer_create.customer_user_errors.map(&:message).join(', ')}")
        return customer_create
      end
      customer_create.customer
    end
    # --- Shopify Cart Integration ---
    # Shopify Cart Mutations
    # Define these at the class level, not inside methods
    # Following official Shopify Storefront API documentation
    CART_CREATE_MUTATION = <<-'GRAPHQL'
      mutation($cartInput: CartInput!) {
        cartCreate(input: $cartInput) {
          cart {
            id
            createdAt
            updatedAt
            checkoutUrl
            lines(first: 10) {
              edges {
                node {
                  id
                  quantity
                  merchandise {
                    ... on ProductVariant {
                      id
                      title
                      priceV2 {
                        amount
                        currencyCode
                      }
                    }
                  }
                }
              }
            }
            cost {
              totalAmount {
                amount
                currencyCode
              }
              subtotalAmount {
                amount
                currencyCode
              }
            }
          }
          userErrors {
            field
            message
          }
        }
      }
    GRAPHQL

    # Parse the mutation once at class level
    CartCreateMutation = Client.parse(CART_CREATE_MUTATION)

    CART_LINES_ADD_MUTATION = <<-'GRAPHQL'
      mutation($cartId: ID!, $lines: [CartLineInput!]!) {
        cartLinesAdd(cartId: $cartId, lines: $lines) {
          cart {
            id
            checkoutUrl
            lines(first: 10) {
              edges {
                node {
                  id
                  quantity
                  merchandise {
                    ... on ProductVariant {
                      id
                      title
                      priceV2 {
                        amount
                        currencyCode
                      }
                    }
                  }
                }
              }
            }
            cost {
              totalAmount {
                amount
                currencyCode
              }
              subtotalAmount {
                amount
                currencyCode
              }
            }
          }
          userErrors {
            field
            message
          }
        }
      }
    GRAPHQL


    # CartCreate mutation as a constant (required by graphql-client)
CartCreateMutation = Client.parse <<-'GRAPHQL'
    mutation($cartInput: CartInput!) {
      cartCreate(input: $cartInput) {
      cart {
      id
    checkoutUrl
    lines(first: 10) {
    edges {
      node {
      id
    merchandise {
    ... on ProductVariant {
      id
    }
    }
    }
    }
    }
    }
    userErrors {
    field
    message
    }
    }
    }
GRAPHQL

def self.create_cart(variant_id:, quantity: 1)
  input = {
      lines: [
        {
        quantity: quantity,
          merchandiseId: variant_id
      }
    ]
    }

    response = Client.query(CartCreateMutation, variables: { cartInput: input })

    if response.errors.any? || response.data&.cart_create&.cart.nil?
    Rails.logger.error("Shopify cartCreate failed: #{response.errors&.messages}")
      return nil
  end

    {
    cart_id: response.data.cart_create.cart.id,
      checkout_url: response.data.cart_create.cart.checkout_url
  }
end


# Add lines to an existing Shopify cart
def self.add_lines_to_cart(cart_id:, variant_id:, quantity: 1)
    lines = [
      {
        quantity: quantity,
        merchandiseId: variant_id
      }
    ]
    response = Client.query(CartLinesAddMutation, variables: { cartId: cart_id, lines: lines })
    if response.errors.any? || response.data&.cart_lines_add&.cart.nil?
    Rails.logger.error("Shopify cartLinesAdd failed: #{response.errors&.messages}")
      return nil
    end
    {
      cart_id: response.data.cart_lines_add.cart.id,
      checkout_url: response.data.cart_lines_add.cart.checkout_url
    }
end
    # Fetch cart by ID from Shopify Storefront API
    CartQuery = Client.parse <<-'GRAPHQL'
      query($cartId: ID!) {
        cart(id: $cartId) {
          id
          checkoutUrl
          lines(first: 20) {
            edges {
              node {
                id
                quantity
                attributes {
                  key
                  value
                }
                merchandise {
                  ... on ProductVariant {
                    id
                    title
                    sku
                    image {
                      url
                      altText
                    }
                    selectedOptions {
                      name
                      value
                    }
                    product {
                      title
                      handle
                      featuredImage {
                        url
                      }
                    }
                  }
                }
                cost {
                  amountPerQuantity {
                    amount
                    currencyCode
                  }
                  subtotalAmount {
                    amount
                    currencyCode
                  }
                }
              }
            }
          }
          cost {
            totalAmount {
              amount
              currencyCode
            }
          }
        }
      }
    GRAPHQL

    CartLinesUpdateMutation = Client.parse <<-'GRAPHQL'
      mutation($cartId: ID!, $lines: [CartLineUpdateInput!]!) {
        cartLinesUpdate(cartId: $cartId, lines: $lines) {
          cart {
            id
            checkoutUrl
            lines(first: 50) {
              edges {
                node {
                  id
                  quantity
                  merchandise {
                    ... on ProductVariant {
                      id
                    }
                  }
                }
              }
            }
          }
          userErrors {
            field
            message
          }
        }
      }
    GRAPHQL


    CartLinesAddMutation = Client.parse <<-'GRAPHQL'
      mutation($cartId: ID!, $lines: [CartLineInput!]!) {
        cartLinesAdd(cartId: $cartId, lines: $lines) {
          cart {
            id
            checkoutUrl
            lines(first: 50) {
              edges {
                node {
                  id
                  quantity
                  merchandise {
                    ... on ProductVariant {
                      id
                    }
                  }
                }
              }
            }
          }
          userErrors {
            field
            message
          }
        }
      }
    GRAPHQL

    CartLinesRemoveMutation = Client.parse <<-'GRAPHQL'
      mutation($cartId: ID!, $lineIds: [ID!]!) {
        cartLinesRemove(cartId: $cartId, lineIds: $lineIds) {
          cart {
            id
            checkoutUrl
            lines(first: 50) {
              edges {
                node {
                  id
                  quantity
                  merchandise {
                    ... on ProductVariant {
                      id
                    }
                  }
                }
              }
            }
          }
          userErrors {
            field
            message
          }
        }
      }
    GRAPHQL

    def self.add_lines_to_cart(cart_id:, variant_id:, quantity: 1)
      lines = [ { quantity: quantity, merchandiseId: variant_id } ]
      response = Client.query(CartLinesAddMutation, variables: { cartId: cart_id, lines: lines })
      if response.errors.any? || response.data&.cart_lines_add&.cart.nil?
        errors = response.data&.cart_lines_add&.user_errors&.map { |e| "#{e.field}: #{e.message}" }.join(", ")
        Rails.logger.error("Shopify cartLinesAdd failed: #{response.errors&.messages} #{errors}")
        return nil
      end
      {
        cart_id: response.data.cart_lines_add.cart.id,
        checkout_url: response.data.cart_lines_add.cart.checkout_url
      }
    end

    def self.remove_cart_lines(cart_id:, line_ids:)
      response = Client.query(CartLinesRemoveMutation, variables: { cartId: cart_id, lineIds: line_ids })
      if response.errors.any? || response.data.cart_lines_remove.cart.nil?
        Rails.logger.error("Shopify cartLinesRemove failed: #{response.errors&.messages}")
        return nil
      end
      response.data.cart_lines_remove.cart
    end

    def self.update_cart_line(cart_id:, line_id:, quantity:)
      lines = [ { id: line_id, quantity: quantity } ]
      response = Client.query(CartLinesUpdateMutation, variables: { cartId: cart_id, lines: lines })
      if response.errors.any? || response.data.cart_lines_update.cart.nil?
        Rails.logger.error("Shopify cartLinesUpdate failed: #{response.errors&.messages}")
        return nil
      end
      response.data.cart_lines_update.cart
    end

    def self.fetch_cart(cart_id)
      response = Client.query(CartQuery, variables: { cartId: cart_id })
      if response.errors.any? || response.data.cart.nil?
        Rails.logger.error("Shopify Storefront API cart fetch error: #{response.errors&.messages}")
        return nil
      end
      response.data.cart
    end
    # Update buyer identity for checkout (customer/shipping info)
    UpdateCartBuyerIdentityMutation = Client.parse <<-'GRAPHQL'
      mutation($buyerIdentity: CartBuyerIdentityInput!, $cartId: ID!) {
        cartBuyerIdentityUpdate(buyerIdentity: $buyerIdentity, cartId: $cartId) {
          cart {
            id
            buyerIdentity {
              email
              phone
              deliveryAddressPreferences {
                ... on MailingAddress {
                  address1
                  city
                  country
                  province
                  firstName
                  lastName
                }
              }
            }
          }
          userErrors {
            field
            message
          }
        }
      }
    GRAPHQL

    def self.update_cart_buyer_identity(cart_id, buyer_identity)
      response = Client.query(UpdateCartBuyerIdentityMutation, variables: { cartId: cart_id, buyerIdentity: buyer_identity })
      if response.errors.any? || response.data.cart_buyer_identity_update.user_errors.any?
        error = response.data.cart_buyer_identity_update.user_errors.map { |e| e.message }.join(", ")
        Rails.logger.error("Shopify cartBuyerIdentityUpdate failed: #{response.errors&.messages} #{error}")
        return { success: false, error: error }
      end
      { success: true, cart: response.data.cart_buyer_identity_update.cart }
    end
  end
end
