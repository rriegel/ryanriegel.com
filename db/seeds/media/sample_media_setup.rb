# Sample script to create placeholder test media files
# Run this to generate test files if you don't have real media yet

require 'fileutils'

media_dir = Rails.root.join('db/seeds/media')
cover_dir = media_dir.join('cover_images')
inline_dir = media_dir.join('inline')

FileUtils.mkdir_p(cover_dir)
FileUtils.mkdir_p(inline_dir)

puts "Creating placeholder test media files..."

# Create placeholder cover images (1x1 pixel PNG)
# In production, you'd use real images
placeholder_png = Base64.decode64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==')

6.times do |i|
  filename = "cover-#{(i + 1).to_s.rjust(2, '0')}.png"
  path = cover_dir.join(filename)
  File.write(path, placeholder_png) unless File.exist?(path)
  puts "  Created: #{filename}"
end

# Create placeholder inline images
3.times do |i|
  filename = "image-#{(i + 1).to_s.rjust(2, '0')}.png"
  path = inline_dir.join(filename)
  File.write(path, placeholder_png) unless File.exist?(path)
  puts "  Created: #{filename}"
end

puts "Done! Replace these placeholders with real media files."
puts "Cover images should be 1200x630px (16:9 aspect ratio)"
