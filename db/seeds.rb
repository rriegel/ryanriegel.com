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
  },
  {
    title: "React Server Components: What Changed and Why It Matters",
    body: <<~HTML,
      <p>React Server Components represent a fundamental shift in how we think about rendering. Here's what you need to know.</p>
      <h2>The Old Model</h2>
      <p>Client-side rendering meant shipping JavaScript bundles, waiting for hydration, then fetching data. Slow and complex.</p>
      <h2>The New Model</h2>
      <p>Server Components run on the server, fetch data directly, and send HTML to the client. No JavaScript overhead for static content.</p>
      <h2>When to Use Client Components</h2>
      <p>Interactivity still needs JavaScript. Forms, animations, and real-time updates belong in Client Components. Everything else can be a Server Component.</p>
    HTML
    excerpt: "Understanding React Server Components — the shift from client-side rendering to server-first architecture.",
    status: :published,
    published_at: 6.days.ago,
    category: categories["JavaScript"],
    tag_names: ["react", "architecture", "tutorial"]
  },
  {
    title: "Building a Design System from Scratch",
    body: <<~HTML,
      <p>A design system isn't just a component library — it's a shared language between design and engineering. Here's how I built mine.</p>
      <h2>Start with Tokens</h2>
      <p>Design tokens are the atoms: colors, spacing, typography, shadows. Define them once, use them everywhere.</p>
      <h2>Component Hierarchy</h2>
      <p>Atoms → Molecules → Organisms → Templates → Pages. This hierarchy keeps complexity manageable and ensures consistency.</p>
      <h2>Documentation is Everything</h2>
      <p>A component without documentation doesn't exist. Show usage examples, props, and edge cases.</p>
    HTML
    excerpt: "Building a design system with tokens, component hierarchy, and documentation — creating a shared language for your team.",
    status: :published,
    published_at: 8.days.ago,
    category: categories["Engineering"],
    tag_names: ["react", "typescript", "architecture"]
  },
  {
    title: "Rails 8: What's New and What's Changed",
    body: <<~HTML,
      <p>Rails 8 brings solid improvements to authentication, deployment, and developer experience. Here's what matters.</p>
      <h2>Built-in Authentication</h2>
      <p>Rails 8 includes a lightweight authentication generator. No more choosing between Devise, Clearance, or rolling your own.</p>
      <h2>Kamal for Deployment</h2>
      <p>Kamal replaces Capistrano as the default deployment tool. Docker-based, zero-downtime deploys out of the box.</p>
      <h2>Performance Improvements</h2>
      <p>Faster boot times, improved query performance, and better memory management across the board.</p>
    HTML
    excerpt: "Rails 8 highlights: built-in authentication, Kamal deployment, and performance improvements that matter.",
    status: :published,
    published_at: 10.days.ago,
    category: categories["Ruby on Rails"],
    tag_names: ["ruby", "rails", "tutorial"]
  },
  {
    title: "The Art of Code Review: Beyond Finding Bugs",
    body: <<~HTML,
      <p>Code review isn't just about catching bugs — it's about knowledge sharing, maintaining quality, and building team trust.</p>
      <h2>What to Look For</h2>
      <p>Correctness first, then readability, then performance. Don't nitpick style when the logic is wrong.</p>
      <h2>How to Give Feedback</h2>
      <p>Be specific, be kind, ask questions instead of making demands. \"Have you considered...\" beats \"Change this to...\"</p>
      <h2>When to Approve</h2>
      <p>Perfect is the enemy of shipped. Approve when the code is good enough, not when it's perfect.</p>
    HTML
    excerpt: "Code review as knowledge sharing — how to give feedback that builds trust and improves code quality.",
    status: :published,
    published_at: 12.days.ago,
    category: categories["Personal"],
    tag_names: ["career", "tutorial"]
  },
  {
    title: "Terraform State Management: Best Practices",
    body: <<~HTML,
      <p>Terraform state is the source of truth for your infrastructure. Mess it up, and you're in for a bad time.</p>
      <h2>Remote State</h2>
      <p>Never store state locally. Use S3 + DynamoDB for locking, or Terraform Cloud for managed state.</p>
      <h2>State Locking</h2>
      <p>Prevent concurrent modifications. DynamoDB provides locking for S3 backends — essential for team workflows.</p>
      <h2>State Manipulation</h2>
      <p>Sometimes you need to move resources in state. <code>terraform state mv</code> and <code>terraform import</code> are your friends.</p>
    HTML
    excerpt: "Terraform state management best practices — remote state, locking, and safe state manipulation.",
    status: :published,
    published_at: 14.days.ago,
    category: categories["DevOps"],
    tag_names: ["terraform", "aws", "architecture"]
  },
  {
    title: "Writing Tests That Don't Slow You Down",
    body: <<~HTML,
      <p>Slow tests kill productivity. Here's how to write tests that give you confidence without slowing you down.</p>
      <h2>Test Pyramid</h2>
      <p>Many unit tests, fewer integration tests, even fewer end-to-end tests. The pyramid keeps your suite fast.</p>
      <h2>Avoid Database Tests</h2>
      <p>Database tests are slow and brittle. Use factories and mocks for unit tests, reserve the database for integration tests.</p>
      <h2>Parallelize</h2>
      <p>Run tests in parallel. RSpec with <code>parallel_tests</code> or Vitest's built-in parallelism can cut your suite time in half.</p>
    HTML
    excerpt: "Writing fast tests that give confidence — test pyramid, avoiding database tests, and parallelization strategies.",
    status: :published,
    published_at: 16.days.ago,
    category: categories["Engineering"],
    tag_names: ["testing", "rails", "tutorial"]
  },
  {
    title: "Astro Content Collections: Type-Safe Markdown",
    body: <<~HTML,
      <p>Astro's Content Collections bring type safety to Markdown. Define schemas, validate frontmatter, and get autocomplete in your templates.</p>
      <h2>Define a Schema</h2>
      <p>Use Zod to define the shape of your content. Required fields, optional fields, enums — all validated at build time.</p>
      <h2>Query Collections</h2>
      <p>Filter, sort, and paginate your content with type-safe queries. No more guessing if a field exists.</p>
      <h2>Render Content</h2>
      <p>Astro compiles Markdown to HTML at build time. Fast, SEO-friendly, and easy to style.</p>
    HTML
    excerpt: "Astro Content Collections bring type safety to Markdown — define schemas, validate frontmatter, and get autocomplete.",
    status: :published,
    published_at: 18.days.ago,
    category: categories["JavaScript"],
    tag_names: ["astro", "typescript", "tutorial"]
  },
  {
    title: "Docker Multi-Stage Builds: Smaller Images, Faster Deploys",
    body: <<~HTML,
      <p>Multi-stage builds let you separate build dependencies from runtime. The result: smaller images, faster deploys, better security.</p>
      <h2>The Problem</h2>
      <p>Build tools (compilers, package managers) are huge. You don't need them at runtime, but they bloat your image.</p>
      <h2>The Solution</h2>
      <p>Use one stage to build, another to run. Copy only the artifacts you need. Your final image is lean and secure.</p>
      <h2>Example: Rails</h2>
      <p>Stage 1: Install gems, compile assets. Stage 2: Copy compiled assets, runtime gems only. Result: 500MB → 150MB.</p>
    HTML
    excerpt: "Docker multi-stage builds separate build dependencies from runtime — smaller images, faster deploys, better security.",
    status: :published,
    published_at: 20.days.ago,
    category: categories["DevOps"],
    tag_names: ["docker", "architecture", "tutorial"]
  },
  {
    title: "Active Record Callbacks: Use with Caution",
    body: <<~HTML,
      <p>Active Record callbacks are powerful but dangerous. They hide logic, create unexpected side effects, and make testing harder.</p>
      <h2>The Problem</h2>
      <p>Callbacks run automatically. When you call <code>save</code>, you don't see what else happens. This makes code hard to understand and debug.</p>
      <h2>When to Use Them</h2>
      <p>Simple, predictable logic: setting timestamps, normalizing data, updating counters. Avoid complex business logic.</p>
      <h2>Alternatives</h2>
      <p>Service objects, explicit methods, or database triggers. Make the logic visible and testable.</p>
    HTML
    excerpt: "Active Record callbacks are powerful but dangerous — when to use them, when to avoid them, and safer alternatives.",
    status: :published,
    published_at: 22.days.ago,
    category: categories["Ruby on Rails"],
    tag_names: ["ruby", "rails", "architecture"]
  },
  {
    title: "Building a CLI Tool with Ruby",
    body: <<~HTML,
      <p>Ruby is great for CLI tools. Thor makes it easy to define commands, parse arguments, and generate help text.</p>
      <h2>Thor Basics</h2>
      <p>Define a class, add methods, and Thor handles the rest. Commands become methods, options become parameters.</p>
      <h2>File Manipulation</h2>
      <p>Thor provides helpers for file operations: copy, template, gsub_file. Perfect for generators and scaffolding.</p>
      <h2>Distribution</h2>
      <p>Package as a gem, install with <code>gem install</code>. Users get a command-line tool with autocomplete and help.</p>
    HTML
    excerpt: "Building CLI tools with Ruby and Thor — define commands, parse arguments, and distribute as gems.",
    status: :published,
    published_at: 24.days.ago,
    category: categories["Ruby on Rails"],
    tag_names: ["ruby", "tutorial"]
  },
  {
    title: "Understanding JavaScript Closures",
    body: <<~HTML,
      <p>Closures are a fundamental JavaScript concept. Understanding them unlocks powerful patterns for data privacy and function factories.</p>
      <h2>What is a Closure?</h2>
      <p>A closure is a function that remembers its lexical scope, even when executed outside that scope. Simple but powerful.</p>
      <h2>Data Privacy</h2>
      <p>Use closures to create private variables. The inner function has access, the outside world doesn't.</p>
      <h2>Function Factories</h2>
      <p>Create specialized functions by closing over parameters. <code>multiplyBy(2)</code> returns a function that doubles its argument.</p>
    HTML
    excerpt: "Understanding JavaScript closures — data privacy, function factories, and the power of lexical scope.",
    status: :published,
    published_at: 26.days.ago,
    category: categories["JavaScript"],
    tag_names: ["typescript", "tutorial"]
  },
  {
    title: "AWS Lambda Cold Starts: Myths and Reality",
    body: <<~HTML,
      <p>Cold starts are Lambda's reputation problem. In practice, they're rarely a real issue — here's why.</p>
      <h2>What is a Cold Start?</h2>
      <p>When Lambda initializes a new container to run your function. This takes time: loading runtime, downloading code, running initialization.</p>
      <h2>How Bad Are They?</h2>
      <p>For most apps, not bad at all. Modern runtimes initialize in milliseconds. Provisioned concurrency eliminates them entirely.</p>
      <h2>When They Matter</h2>
      <p>Latency-sensitive APIs, synchronous user flows. For background jobs, async processing, or scheduled tasks — who cares?</p>
    HTML
    excerpt: "AWS Lambda cold starts are rarely a real issue — understanding when they matter and how to mitigate them.",
    status: :published,
    published_at: 28.days.ago,
    category: categories["DevOps"],
    tag_names: ["aws", "architecture"]
  },
  {
    title: "The Case for Boring Technology",
    body: <<~HTML,
      <p>Choose boring technology. It's reliable, well-understood, and lets you focus on what makes your product unique.</p>
      <h2>Innovation Tokens</h2>
      <p>You get a limited number of innovation tokens. Spend them on your core differentiator, not your infrastructure.</p>
      <h2>PostgreSQL vs. The New Hotness</h2>
      <p>PostgreSQL is boring. It's also fast, reliable, and feature-complete. The new database might be faster, but it's unproven.</p>
      <h2>When to Innovate</h2>
      <p>Innovate where it matters. If your product is a novel algorithm, spend tokens there. Not on your database.</p>
    HTML
    excerpt: "Choose boring technology — it's reliable, well-understood, and lets you focus on what makes your product unique.",
    status: :published,
    published_at: 30.days.ago,
    category: categories["Personal"],
    tag_names: ["architecture", "career"]
  },
  {
    title: "RSpec Best Practices: Writing Maintainable Tests",
    body: <<~HTML,
      <p>Good tests are readable, maintainable, and fast. Here are the RSpec patterns I use to achieve all three.</p>
      <h2>Describe Blocks</h2>
      <p>Use <code>describe</code> for the unit under test, <code>context</code> for different scenarios. Keep nesting shallow — three levels max.</p>
      <h2>Let vs. Before</h2>
      <p>Use <code>let</code> for lazy-loaded test data. Use <code>before</code> for setup that runs regardless. Avoid instance variables.</p>
      <h2>One Assertion Per Test</h2>
      <p>Each test should verify one behavior. If it fails, you should know exactly what broke. Multiple assertions = confusion.</p>
    HTML
    excerpt: "RSpec best practices for writing readable, maintainable, fast tests — describe blocks, let vs before, one assertion per test.",
    status: :published,
    published_at: 32.days.ago,
    category: categories["Ruby on Rails"],
    tag_names: ["ruby", "rails", "testing", "tutorial"]
  },
  {
    title: "Building Accessible Forms in React",
    body: <<~HTML,
      <p>Accessibility isn't optional. Here's how to build forms that work for everyone — keyboard navigation, screen readers, and all.</p>
      <h2>Labels</h2>
      <p>Every input needs a label. Use <code>&lt;label htmlFor=\"id\"&gt;</code> or wrap the input. No exceptions.</p>
      <h2>Error Messages</h2>
      <p>Connect errors to inputs with <code>aria-describedby</code>. Screen readers will announce them when the input is focused.</p>
      <h2>Focus Management</h2>
      <p>After submission, move focus to the success message or first error. Don't leave users stranded.</p>
    HTML
    excerpt: "Building accessible forms in React — labels, error messages, focus management, and keyboard navigation.",
    status: :published,
    published_at: 34.days.ago,
    category: categories["JavaScript"],
    tag_names: ["react", "typescript", "tutorial"]
  },
  {
    title: "Database Indexing Strategies for Rails",
    body: <<~HTML,
      <p>Indexes are the difference between a fast app and a slow app. Here's how to use them effectively in Rails.</p>
      <h2>When to Index</h2>
      <p>Index columns you query frequently: foreign keys, WHERE clauses, ORDER BY columns. Don't index everything — indexes slow writes.</p>
      <h2>Composite Indexes</h2>
      <p>For queries with multiple conditions, use composite indexes. Order matters: put the most selective column first.</p>
      <h2>Partial Indexes</h2>
      <p>Index only the rows you query. <code>WHERE published = true</code> is smaller and faster than indexing all rows.</p>
    HTML
    excerpt: "Database indexing strategies for Rails — when to index, composite indexes, and partial indexes for performance.",
    status: :draft,
    published_at: nil,
    category: categories["Engineering"],
    tag_names: ["postgresql", "rails", "architecture"]
  },
  {
    title: "My Development Environment in 2026",
    body: <<~HTML,
      <p>After years of tweaking, I've settled on a development setup that works. Here's what I use and why.</p>
      <h2>Editor: Neovim</h2>
      <p>Fast, customizable, and keyboard-driven. LSP for intelligence, Treesitter for syntax highlighting. It's everything I need.</p>
      <h2>Terminal: WezTerm</h2>
      <p>GPU-accelerated, Lua-configurable, multiplexer built-in. Replaced iTerm2 + tmux with a single tool.</p>
      <h2>Shell: Fish</h2>
      <p>Sane defaults, excellent autocomplete, no configuration needed. I stopped fighting Bash syntax years ago.</p>
    HTML
    excerpt: "My 2026 development environment — Neovim, WezTerm, Fish shell, and the tools that make me productive.",
    status: :draft,
    published_at: nil,
    category: categories["Personal"],
    tag_names: ["career"]
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
