# db/seeds.rb — Development seed data
#
# Usage:
#   bin/rails db:seed        # Create seed data
#   bin/rails db:seed:reseed # Destroy and recreate (alias for db:drop db:create db:migrate db:seed)
#
# To remove seed data without dropping the database:
#   bin/rails db:seed:destroy

puts "Seeding database..."

# --- Admin User ---
admin = User.find_or_create_by!(email: "admin@example.com") do |u|
  u.password = "admin!!1"
  u.password_confirmation = "admin!!1"
end
puts "  User: #{admin.email}"

# --- Categories ---
categories = {}
[
  { name: "Engineering" },
  { name: "DevOps" },
  { name: "Ruby on Rails" },
  { name: "JavaScript" },
  { name: "Personal" }
].each do |attrs|
  cat = Category.find_or_create_by!(name: attrs[:name])
  categories[attrs[:name]] = cat
  puts "  Category: #{cat.name} (#{cat.slug})"
end

# --- Tags ---
tags = {}
[
  "ruby", "rails", "typescript", "astro", "docker",
  "aws", "testing", "ci-cd", "react", "postgresql",
  "terraform", "architecture", "career", "tutorial"
].each do |name|
  tag = Tag.find_or_create_by!(name: name)
  tags[name] = tag
  puts "  Tag: #{tag.name} (#{tag.slug})"
end

# --- Posts ---
posts_data = [
  {
    title: "Building a Serverless Blog Platform with Rails and Astro",
    body: <<~HTML,
      <p>After years of using WordPress, I decided to build my own blog platform from scratch. The goal was simple: full control over the stack, learn new technologies, and have a system that scales with my needs.</p>
      <h2>The Stack</h2>
      <p>I chose <strong>Ruby on Rails 8.1</strong> for the API backend and <strong>Astro</strong> for the frontend. Rails gives me a robust, well-tested API with JWT authentication, while Astro provides blazing-fast server-side rendering with minimal JavaScript.</p>
      <h2>Why Astro?</h2>
      <p>Astro's island architecture means I can ship zero JavaScript by default and only hydrate components that need interactivity. For a blog, that's perfect — most pages are static content that should load instantly.</p>
      <blockquote>The best JavaScript is no JavaScript.</blockquote>
      <p>Combined with PostgreSQL for storage and Docker for local development, the stack is modern, maintainable, and fun to work with.</p>
    HTML
    excerpt: "Why I chose Rails + Astro for my personal blog platform, and how the island architecture delivers blazing-fast page loads.",
    status: :published,
    published_at: 2.weeks.ago,
    category: categories["Engineering"],
    tag_names: ["ruby", "rails", "astro", "architecture"]
  },
  {
    title: "TDD in Rails: A Practical Guide to RSpec and FactoryBot",
    body: <<~HTML,
      <p>Test-driven development isn't just a practice — it's a design tool. When you write tests first, you're forced to think about interfaces before implementation.</p>
      <h2>Setting Up RSpec</h2>
      <p>Start by adding <code>rspec-rails</code> and <code>factory_bot_rails</code> to your Gemfile. Then generate your test helper:</p>
      <pre><code>bin/rails generate rspec:install</code></pre>
      <h2>Model Specs</h2>
      <p>Always test validations and associations first. These are the contracts your model makes with the rest of the application:</p>
      <pre><code>describe Post do
  it { should validate_presence_of(:title) }
  it { should belong_to(:category).optional }
end</code></pre>
      <h2>Request Specs</h2>
      <p>For API endpoints, request specs verify the full stack — routing, controllers, serialization, and database queries all in one test.</p>
    HTML
    excerpt: "How to set up RSpec with FactoryBot in a Rails API, and why writing tests first leads to better-designed code.",
    status: :published,
    published_at: 1.week.ago,
    category: categories["Ruby on Rails"],
    tag_names: ["ruby", "rails", "testing", "tutorial"]
  },
  {
    title: "CI/CD with GitHub Actions: From Zero to Production",
    body: <<~HTML,
      <p>Every project deserves a CI pipeline. It catches bugs before they reach production, enforces code quality, and gives you confidence to deploy.</p>
      <h2>The Pipeline</h2>
      <p>My CI runs four jobs on every pull request:</p>
      <ul>
        <li><strong>scan_ruby</strong> — Brakeman and bundler-audit for security vulnerabilities</li>
        <li><strong>scan_js</strong> — npm audit for JavaScript dependency vulnerabilities</li>
        <li><strong>lint</strong> — RuboCop for code style consistency</li>
        <li><strong>test</strong> — RSpec for the backend, Vitest for the frontend</li>
      </ul>
      <h2>Branch Protection</h2>
      <p>The key is requiring all checks to pass before merging. GitHub's branch protection rules make this straightforward — just enable "Require status checks to pass before merging" on your main branch.</p>
    HTML
    excerpt: "Setting up a complete CI pipeline with GitHub Actions — security scanning, linting, and testing for a Rails + Astro project.",
    status: :published,
    published_at: 3.days.ago,
    category: categories["DevOps"],
    tag_names: ["ci-cd", "testing", "aws", "tutorial"]
  },
  {
    title: "Docker for Rails Development: A Makefile-Driven Workflow",
    body: <<~HTML,
      <p>Running PostgreSQL in Docker while keeping Rails native gives you the best of both worlds: isolated database with no setup friction, and full debugging access to your Ruby code.</p>
      <h2>The Setup</h2>
      <p>A single Docker container for PostgreSQL, managed by a Makefile:</p>
      <pre><code>docker run -d \\
  --name myapp-db \\
  -e POSTGRES_PASSWORD=*** \\
  -p 5434:5432 \\
  postgres:16-alpine</code></pre>
      <h2>Why Not Docker Compose?</h2>
      <p>For a single service, Compose adds complexity without benefit. A Makefile target is simpler and keeps the database lifecycle explicit.</p>
    HTML
    excerpt: "Using Docker for PostgreSQL while keeping Rails native — a Makefile-driven workflow that avoids Docker Compose complexity.",
    status: :published,
    published_at: 5.days.ago,
    category: categories["DevOps"],
    tag_names: ["docker", "rails", "postgresql", "tutorial"]
  },
  {
    title: "TypeScript with Astro: Type-Safe API Calls",
    body: <<~HTML,
      <p>When your frontend talks to an API, type safety prevents an entire class of bugs. Here's how I built a typed API client for my Astro frontend.</p>
      <h2>The API Client</h2>
      <p>A generic fetch wrapper that handles errors, parses JSON, and returns typed responses:</p>
      <pre><code>async function fetchApi&lt;T&gt;(path: string): Promise&lt;T&gt; {
  const res = await fetch(`${API_URL}${path}`);
  if (!res.ok) throw new ApiError(res.status);
  return res.json();
}</code></pre>
      <p>Combined with TypeScript interfaces matching the Rails serializers, you get compile-time guarantees that your frontend and backend agree on data shapes.</p>
    HTML
    excerpt: "Building a type-safe API client for Astro that catches mismatches between frontend and backend at compile time.",
    status: :published,
    published_at: 1.day.ago,
    category: categories["JavaScript"],
    tag_names: ["typescript", "astro", "react", "tutorial"]
  },
  {
    title: "Infrastructure as Code: Deploying to AWS with Terraform",
    body: <<~HTML,
      <p>Manual AWS console clicks don't scale. Terraform lets you define your entire infrastructure in code — reproducible, reviewable, and version-controlled.</p>
      <h2>What We're Building</h2>
      <p>An S3 bucket for static assets, CloudFront for CDN distribution, Lambda functions for serverless API endpoints, and API Gateway for routing. All defined in Terraform and deployed via GitHub Actions.</p>
      <h2>State Management</h2>
      <p>Terraform state lives in an S3 bucket with DynamoDB locking. This lets multiple developers work safely without state conflicts.</p>
    HTML
    excerpt: "Planning an AWS deployment with Terraform — S3, CloudFront, Lambda, and API Gateway defined as code.",
    status: :draft,
    published_at: nil,
    category: categories["DevOps"],
    tag_names: ["aws", "terraform", "architecture"]
  },
  {
    title: "Why I Left My Job to Build in Public",
    body: <<~HTML,
      <p>After three years as a software engineer, I made the decision to leave my comfortable job and build projects in public. Here's why.</p>
      <h2>The Comfort Trap</h2>
      <p>It's easy to get comfortable. Stable salary, familiar codebase, good teammates. But comfort is the enemy of growth.</p>
      <h2>What's Next</h2>
      <p>I'm building tools I wish existed, writing about what I learn, and sharing the process openly. This blog is part of that journey.</p>
    HTML
    excerpt: "Reflections on leaving a comfortable engineering role to pursue independent projects and open-source work.",
    status: :draft,
    published_at: nil,
    category: categories["Personal"],
    tag_names: ["career"]
  },
  {
    title: "PostgreSQL Performance Tips for Rails Developers",
    body: <<~HTML,
      <p>PostgreSQL is incredibly powerful, but misusing it can bring your app to its knees. Here are the performance patterns I've learned the hard way.</p>
      <h2>Use EXPLAIN ANALYZE</h2>
      <p>Before optimizing, measure. <code>EXPLAIN ANALYZE</code> shows you exactly what PostgreSQL is doing — sequential scans, index usage, join strategies.</p>
      <h2>N+1 Queries</h2>
      <p>The silent killer. Use <code>includes</code> to eager-load associations and watch your query count drop from hundreds to single digits.</p>
      <h2>Connection Pooling</h2>
      <p>Each Rails process holds database connections. With Puma's thread pool, that's <code>threads × workers</code> connections. Size your pool carefully.</p>
    HTML
    excerpt: "Practical PostgreSQL performance patterns every Rails developer should know — from EXPLAIN ANALYZE to connection pooling.",
    status: :published,
    published_at: 4.days.ago,
    category: categories["Engineering"],
    tag_names: ["postgresql", "rails", "architecture"]
  }
]

posts_data.each do |data|
  tag_names = data.delete(:tag_names)
  post = Post.find_or_create_by!(title: data[:title]) do |p|
    p.body = data[:body]
    p.excerpt = data[:excerpt]
    p.status = data[:status]
    p.published_at = data[:published_at]
    p.category = data[:category]
  end

  # Associate tags
  tag_names.each do |name|
    post.tags << tags[name] unless post.tags.include?(tags[name])
  end

  puts "  Post: #{post.title} [#{post.status}] (#{post.slug})"
end

puts ""
puts "Done! Seeded:"
puts "  #{User.count} user(s)"
puts "  #{Category.count} categories"
puts "  #{Tag.count} tags"
puts "  #{Post.count} posts (#{Post.published.count} published, #{Post.drafts.count} drafts)"
puts ""
puts "Admin login: admin@example.com / admin!!1"
