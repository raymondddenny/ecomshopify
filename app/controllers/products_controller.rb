class ProductsController < ApplicationController
  def index
    @products = Shopify::StorefrontService.fetch_products(first: 12)
  end
end
