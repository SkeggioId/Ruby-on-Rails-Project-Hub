# 1. Product Model with Validations
class Product < ApplicationRecord
  validates :name, presence: true
  validates :price, numericality: { greater_than: 0 }
end

# 2. Shopping Cart Creation
class Cart < ApplicationRecord
  has_many :cart_items
  has_many :products, through: :cart_items
end

# 3. Add Item to Cart
class CartItemsController < ApplicationController
  def create
    cart = current_cart
    product = Product.find(params[:product_id])
    cart.add_product(product)

    redirect_to cart_path
  end
end

# 4. Checkout Process
class OrdersController < ApplicationController
  def create
    order = Order.new(order_params)
    order.cart = current_cart
    order.save
    session[:cart_id] = nil
    redirect_to root_path, notice: 'Thank you for your order!'
  end
end

# 5. Payment Integration (Example with Stripe)
class ChargesController < ApplicationController
  def create
    customer = Stripe::Customer.create(
      email: params[:stripeEmail],
      source: params[:stripeToken]
    )

    charge = Stripe::Charge.create(
      customer: customer.id,
      amount: current_cart.total * 100, # Amount in cents
      description: 'E-commerce Purchase',
      currency: 'usd'
    )

    # Handle successful charge
  rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to new_charge_path
  end
end

# 6. Dynamic Product Search
class ProductsController < ApplicationController
  def index
    if params[:search]
      @products = Product.where('name LIKE ?', "%#{params[:search]}%")
    else
      @products = Product.all
    end
  end
end

# 7. User Authentication (Devise Gem)
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
end

# 8. Admin Namespace for Product Management
namespace :admin do
  resources :products
end

# 9. Image Uploads (Active Storage)
class ProductsController < ApplicationController
  def create
    @product = Product.new(product_params)
    @product.images.attach(params[:product][:images])
    @product.save
  end
end

# 10. Implementing Discount Logic
class Cart
  def apply_discount(code)
    discount = Discount.find_by(code: code)
    if discount&.valid_for_use?
      self.total_price -= discount.amount
      discount.use!
    end
  end
end
