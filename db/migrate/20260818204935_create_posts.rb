class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title
      t.string :slug
      t.text :body
      t.text :excerpt
      t.integer :status
      t.datetime :published_at

      t.timestamps
    end
  end
end
