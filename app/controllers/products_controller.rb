class ProductsController < ApplicationController
  def index
    @products = Shopify::StorefrontService.fetch_products(first: 12)
  end

  def show
    @product = Shopify::StorefrontService.fetch_product_by_handle(params[:id])
    if @product.nil?
      redirect_to products_path, alert: 'Product not found.'
    end
  end
end
