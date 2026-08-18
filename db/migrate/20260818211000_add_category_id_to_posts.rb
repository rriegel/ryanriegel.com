class AddCategoryIdToPosts < ActiveRecord::Migration[8.1]
  def change
    add_reference :posts, :category, foreign_key: true
  end
end
