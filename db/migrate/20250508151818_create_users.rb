class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email
      t.string :password_digest
      t.string :shopify_customer_id
      t.string :first_name
      t.string :last_name

      t.timestamps
    end
  end
end
