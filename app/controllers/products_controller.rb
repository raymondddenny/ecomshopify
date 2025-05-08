class ProductsController < ApplicationController
  def index
    @products = Shopify::StorefrontService.fetch_products(first: 12)
  end

  def show
    @product = Shopify::StorefrontService.fetch_product_by_handle(params[:id])
    if @product.nil?
      redirect_to products_path, alert: 'Product not found.'
      return
    end
    @related_products = []
    if @product.id.present?
      @related_products = Shopify::StorefrontService.fetch_product_recommendations(@product.id) || []
    end
  end
end
