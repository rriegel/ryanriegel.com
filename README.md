# ryanriegel.com

Personal website and blog built with Rails 8.1 API + PostgreSQL.

## Purpose

A custom-built blog platform for publishing technical articles, tutorials, and thoughts. Built from scratch to learn Rails and have full control over the content management system.

## Tech Stack

- **Backend**: Ruby on Rails 8.1.3 (API mode)
- **Database**: PostgreSQL 16 (via Docker)
- **Testing**: RSpec with FactoryBot
- **Deployment**: AWS (planned)

## Prerequisites

- Ruby 3.4.1 (managed via rbenv)
- Docker (for PostgreSQL)
- Bundler

## Local Development Setup

### 1. Start PostgreSQL via Docker

```bash
docker run -d \
  --name ryanriegel-com-db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=*** \
  -p 5433:5432 \
  postgres:16-alpine
```

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

## Running Tests

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
spec/
  factories/    # FactoryBot definitions
  models/       # Model specs
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

- Database runs on port 5433 (not default 5432) to avoid conflicts
- All secrets are managed via environment variables
- The project uses PostgreSQL exclusively (no SQLite)
