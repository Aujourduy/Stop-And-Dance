# Stop & Dance - Deployment Guide

## Production Deployment

### Prerequisites

1. Server with Docker and Docker Compose installed
2. Domain name pointing to server
3. Ports 8080, 8443 available (or configure nginx/Caddy integration)

### Initial Setup

1. **Clone repository:**
```bash
git clone <repository-url> 3graces-v2
cd 3graces-v2
```

2. **Configure environment variables:**
```bash
cp .env.example .env
nano .env  # Fill in all required values
```

Required variables:
- `DB_PASSWORD`: Strong password for PostgreSQL
- `SECRET_KEY_BASE`: Generate with `rails secret`
- `ADMIN_USERNAME`: Admin panel username
- `ADMIN_PASSWORD`: Admin panel password
- `ALERT_EMAIL`: Email for scraping failure alerts

3. **Ensure Claude CLI is authenticated:**
```bash
# Claude CLI credentials are mounted from ~/.claude
# Authenticate once on the host before deploying
claude auth
```

### Deploy

Run the deployment script:
```bash
./scripts/deploy.sh
```

The script will:
- Validate environment variables
- Pull latest code
- Build Docker images
- Start containers (web, jobs, db, caddy)
- Run migrations

### Access

- **Public site:** http://localhost:8080 (or your domain)
- **Admin panel:** http://localhost:8080/admin
  - Username/password from .env

### Database Backups

Set up daily backups via cron:
```bash
crontab -e
# Add: 0 2 * * * /home/dang/stop-and-dance/scripts/backup-db.sh
```

Backups stored in `/home/dang/backups/stop-and-dance/` (30 day retention)

### Monitoring

**View logs:**
```bash
docker compose logs -f           # All containers
docker compose logs -f web       # Web server only
docker compose logs -f jobs      # Background jobs only
```

**Check job queue:**
```bash
docker compose exec jobs bundle exec rake solid_queue:info
```

**Trigger manual scraping:**
```bash
docker compose exec jobs bundle exec rake scraping:dispatch_all
```

### Troubleshooting

**Containers not starting:**
```bash
docker compose ps
docker compose logs
```

**Database connection issues:**
```bash
docker compose exec web bundle exec rails db:migrate:status
```

**Clear and rebuild:**
```bash
docker compose down
docker compose up -d --build
```

### Port Conflicts

Currently using ports 8080/8443 to avoid conflicts with:
- Docker v1: 3000/3001
- Nextcloud: 80/443

**TODO:** Integrate Caddy with existing nginx or migrate Nextcloud to Caddy for unified reverse proxy with automatic HTTPS.

### Security Notes

- `.env` file is in `.gitignore` - never commit secrets
- Admin panel protected with HTTP Basic Auth
- All admin pages have `noindex, nofollow` robots meta
- Force HTTPS in production via Caddy
- Claude CLI credentials persisted in `~/.claude` volume mount
