# 3 Graces - Community Event Calendar

Rails 8 application for aggregating and displaying events from Paris spiritual/holistic communities.

## Prerequisites

* Ruby 3.3+
* PostgreSQL 16+
* Rails 8.1+

## Configuration

**Environment Variables:**

Copy `.env.example` to `.env` and set your production credentials before running the app:

```bash
cp .env.example .env
```

Edit `.env` with your actual credentials (never commit this file).

## Setup

```bash
bundle install
rails db:create db:migrate db:seed
```

## Running the Application

```bash
rails server
```

## Background Jobs

Development mode runs jobs inline (immediately). To test worker processes:

```bash
rails solid_queue:start
```
