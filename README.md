# ryanriegel.com

Personal website and blog built with Rails 8.1 API + PostgreSQL.

## Purpose

A custom-built blog platform for publishing media, articles, tutorials, and thoughts. Built from scratch to bring my Rails experience to my personal projects and have full control over the content management system.

## Tech Stack

- **Backend**: Ruby on Rails 8.1.3 (API mode)
- **Frontend**: Astro (server-side rendering)
- **Database**: PostgreSQL 16 (via Docker)
- **Testing**: RSpec with FactoryBot
- **Deployment**: AWS (planned)

## Prerequisites

- Ruby 3.4.1 (managed via rbenv)
- Node.js 22+ and npm
- Docker (for PostgreSQL)
- Bundler

## Local Development Setup (First Time)

### 1. Start PostgreSQL via Docker

```bash
docker run -d \
  --name ryanriegel-com-db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=*** \
  -e POSTGRES_DB=ryanriegel_com_development \
  -p 5434:5432 \
  postgres:16-alpine
```

Note: Port 5434 is used to avoid conflicts with other projects

### 2. Set up environment variables

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
export DATABASE_PASSWORD=***
```

Then reload your shell or run `source ~/.bashrc`.

### 3. Install dependencies

```bash
bundle install
```

### 4. Create and migrate the database

```bash
rails db:create
rails db:migrate
```

### 5. Start the Rails server

```bash
rails server
```

The API will be available at `http://localhost:3000`.

### 6. Set up the frontend

```bash
cd frontend
npm install
cp .env.example .env
npm run dev
```

The frontend will be available at `http://localhost:4321`.

## Frontend Commands

All frontend commands must be run from the `frontend/` directory:

```bash
cd frontend

# Development server (hot reload)
npm run dev

# Production build
npm run build

# Preview production build locally
npm run preview

# Type checking
npm run check
```

## Daily Development (Already Set Up)

Once the project is set up, here's what starting and stopping looks like day-to-day:

### Starting work

```bash
# 1. Start the database
docker start ryanriegel-com-db

# 2. Start the Rails server (in one terminal)
cd ~/work/ryanriegel.com
rails server

# 3. Start the Astro dev server (in another terminal)
cd ~/work/ryanriegel.com/frontend
npm run dev
```

### Stopping work

```bash
# Stop the Rails server (Ctrl+C in the terminal where it's running)
# Stop the Astro dev server (Ctrl+C in the terminal where it's running)

# Stop the database (optional — leave it running if you'll be back soon)
docker stop ryanriegel-com-db
```

### Useful Docker commands

```bash
# Check if the database is running
docker ps | grep ryanriegel-com-db

# View database logs
docker logs ryanriegel-com-db

# Connect to the database directly
PGPASSWORD=*** psql -h 127.0.0.1 -p 5434 -U postgres -d ryanriegel_com_development
```

### If the database password stops working

The password is only set on first container creation. If it drifts, reset it:

```bash
docker exec -it ryanriegel-com-db psql -U postgres -c "ALTER USER postgres PASSWORD 'postgres';"
```

## Running Tests

Before running tests for the first time, create and migrate the test database:

```bash
RAILS_ENV=test bin/rails db:create db:migrate
```

Then run the test suite:

```bash
bundle exec rspec
```

The test suite includes:
- Model specs (validations, associations, scopes)
- Request specs (API endpoints)
- Factory definitions for test data

## Project Structure

```
app/
  controllers/  # API controllers
  models/       # ActiveRecord models
    post.rb     # Blog posts
    category.rb # Post categories
    tag.rb      # Post tags
config/
  database.yml  # PostgreSQL configuration
db/
  migrate/      # Database migrations
frontend/
  src/
    layouts/    # Astro layouts (base HTML structure)
    pages/      # Astro pages (routes)
      index.astro      # Homepage
      about.astro      # About page
      404.astro        # 404 page
      blog/
        index.astro    # Blog listing
        [slug].astro   # Individual post
    lib/
      api.ts           # API client (typed fetch functions)
    components/        # Reusable Astro components
spec/
  factories/    # FactoryBot definitions
  models/       # Model specs
  requests/     # API request specs
```

## Database Schema

- **posts**: title, slug, body, excerpt, status (draft/published), published_at, category_id
- **categories**: name, slug
- **tags**: name, slug
- **post_tags**: join table (post_id, tag_id)

## Development Workflow

1. Create a feature branch
2. Write tests first (TDD)
3. Implement the feature
4. Run `bundle exec rspec` to verify
5. Commit and push

## Deployment

Deployment configuration is planned for AWS with:
- S3 for static assets
- CloudFront for CDN
- Lambda for serverless functions
- API Gateway for routing
- SES for email notifications

## Notes

- Database runs on port 5434 (not default 5432) to avoid conflicts with other projects
- All secrets are managed via environment variables
- The project uses PostgreSQL exclusively (no SQLite)
