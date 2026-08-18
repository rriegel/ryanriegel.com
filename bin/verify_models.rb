#!/usr/bin/env ruby
# Verification script for blog models
# Run: rails runner bin/verify_models.rb

puts "=== Verifying Blog Models ==="
puts

# Test 1: Run migration
puts "1. Running migration..."
result = system("rails db:migrate")
puts result ? "   ✓ Migration successful" : "   ✗ Migration failed"
puts

# Test 2: Create a category
puts "2. Creating a category..."
begin
  category = Category.create!(name: "Technology", slug: "technology")
  puts "   ✓ Category created: #{category.name} (#{category.slug})"
rescue => e
  puts "   ✗ Failed: #{e.message}"
end
puts

# Test 3: Create a tag
puts "3. Creating a tag..."
begin
  tag = Tag.create!(name: "Ruby", slug: "ruby")
  puts "   ✓ Tag created: #{tag.name} (#{tag.slug})"
rescue => e
  puts "   ✗ Failed: #{e.message}"
end
puts

# Test 4: Create a post with associations
puts "4. Creating a post with associations..."
begin
  post = Post.create!(
    title: "Test Post",
    body: "This is a test post body with some content.",
    status: :draft,
    category: category
  )
  post.tags << tag
  puts "   ✓ Post created: #{post.title}"
  puts "   ✓ Post has category: #{post.category.name}"
  puts "   ✓ Post has tags: #{post.tags.map(&:name).join(', ')}"
rescue => e
  puts "   ✗ Failed: #{e.message}"
end
puts

# Test 5: Test validations
puts "5. Testing validations..."
begin
  invalid_post = Post.new(title: "", body: "")
  if invalid_post.invalid?
    puts "   ✓ Validations working (caught invalid post)"
  else
    puts "   ✗ Validations not working"
  end
rescue => e
  puts "   ✗ Failed: #{e.message}"
end
puts

# Test 6: Test slug generation
puts "6. Testing slug generation..."
begin
  auto_slug_post = Post.new(title: "My Awesome Post", body: "Content here", status: :draft)
  auto_slug_post.valid?
  if auto_slug_post.slug == "my-awesome-post"
    puts "   ✓ Slug auto-generated: #{auto_slug_post.slug}"
  else
    puts "   ✗ Slug not auto-generated correctly: #{auto_slug_post.slug}"
  end
rescue => e
  puts "   ✗ Failed: #{e.message}"
end
puts

# Test 7: Test scopes
puts "7. Testing scopes..."
begin
  published_count = Post.published.count
  draft_count = Post.drafts.count
  puts "   ✓ Published posts: #{published_count}"
  puts "   ✓ Draft posts: #{draft_count}"
rescue => e
  puts "   ✗ Failed: #{e.message}"
end
puts

puts "=== Verification Complete ==="
