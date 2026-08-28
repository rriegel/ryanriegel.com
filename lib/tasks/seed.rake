namespace :db do
  namespace :seed do
    desc "Destroy all seeded data (posts, tags, categories, users)"
    task destroy: :environment do
      puts "Destroying seed data..."

      # Delete in reverse dependency order
      PostTag.delete_all
      Post.delete_all
      Tag.delete_all
      Category.delete_all
      User.where(email: "admin@example.com").delete_all

      puts "Done! Removed:"
      puts "  #{User.where(email: "admin@example.com").count} admin user(s)"
      puts "  #{Category.count} categories"
      puts "  #{Tag.count} tags"
      puts "  #{Post.count} posts"
    end

    desc "Drop, recreate, migrate, and seed the database"
    task reseed: :environment do
      puts "Reseeding database..."
      Rake::Task["db:drop"].invoke
      Rake::Task["db:create"].invoke
      Rake::Task["db:migrate"].invoke
      Rake::Task["db:seed"].invoke
      puts "Database reset and seeded successfully!"
    end
  end
end
