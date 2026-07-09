# Docker WordPress (Headless-ready)

Configuration to run WordPress locally with Docker and reuse the same setup for deployment on AWS.

Files

- `docker-compose.yml`: starts WordPress, MariaDB and phpMyAdmin for local development.
- `docker-compose.prod.yml`: production-oriented compose file (binds to port 80).
- `.env`: shared environment variables.
- `wordpress/Dockerfile`: custom WordPress image with WP-CLI and initialization script.

Local usage

1. Copy and review `.env` (or `.env.example`) and adjust values.
2. Start services:

```bash
docker compose up -d --build
```

3. Open WordPress at `http://localhost:8000` and phpMyAdmin at `http://localhost:8080`.

Headless mode

This project supports an optional "headless" mode controlled by the `HEADLESS` environment variable in `.env`.

- `HEADLESS=false` (default): regular WordPress behavior.
- `HEADLESS=true`: on startup the container will try to install WordPress automatically (if not installed), install and activate recommended plugins for headless use (`WPGraphQL` and `JWT Authentication`), and add a mu-plugin to enable CORS from the front-end domain defined in `FRONTEND_URL`.

Automatic flow when `HEADLESS=true`

1. Set `HEADLESS=true` and `FRONTEND_URL` in `.env` (e.g. `http://localhost:3000`).
2. Bring up the stack and (optionally) the image will auto-install WordPress using the following env vars if WP isn't installed:

- `WORDPRESS_SITE_URL` (default `http://localhost:8000`)
- `WORDPRESS_SITE_TITLE` (default `WordPress`)
- `WORDPRESS_ADMIN_USER`, `WORDPRESS_ADMIN_PASSWORD`, `WORDPRESS_ADMIN_EMAIL`

3. If needed, restart the WordPress container to trigger the initialization script:

```bash
docker compose restart wordpress
```

Manual WP-CLI plugin install

If you prefer to install plugins manually instead of relying on the auto-installer:

```bash
docker compose exec wordpress wp plugin install wp-graphql --activate --allow-root --path=/var/www/html
docker compose exec wordpress wp plugin install jwt-authentication-for-wp-rest-api --activate --allow-root --path=/var/www/html
```

Production notes

- Use Amazon RDS (or Aurora) for the database in production rather than running MariaDB in a container.
- Offload media to S3 and serve it via CloudFront (consider `WP Offload Media`).
- Secure secrets with AWS Secrets Manager or Parameter Store; do not store production passwords in plain `.env` files.
- Use an HTTPS-terminating load balancer (ALB) or reverse proxy, and do not expose admin interfaces unnecessarily.

Security and configuration

- Change all default passwords before exposing the service to the internet.
- Consider adding object caching (Redis/Elasticache) and a CDN for static assets.

If you want, I can also add an `README.en.md` link to the project root or prepare Terraform/CloudFormation templates for an AWS ECS + RDS + S3 deployment.
