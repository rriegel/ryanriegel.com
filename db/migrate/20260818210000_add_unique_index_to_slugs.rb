class AddUniqueIndexToSlugs < ActiveRecord::Migration[8.1]
  def change
    add_index :posts, :slug, unique: true
    add_index :categories, :slug, unique: true
    add_index :tags, :slug, unique: true
  end
end
