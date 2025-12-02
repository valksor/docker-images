# Valksor Docker Images

[![valksor](https://badgen.net/static/org/valksor/green)](https://github.com/valksor)
[![BSD-3-Clause](https://img.shields.io/badge/BSD--3--Clause-green?style=flat)](https://github.com/valksor/docker-images/blob/master/LICENSE)

Production-ready, highly optimized Docker images for modern web applications. Built by SIA Valksor with focus on performance, security, and minimal size.

Available images: **Base Images**, **PHP variants**, **Nginx**, **PostgreSQL**, **cURL**, **Action utilities**, and more.

## Quick Start

Pull and run any image in seconds:

```bash
# PHP-FPM with extensions
docker run -d --name php-fpm ghcr.io/valksor/php/fpm:latest

# Nginx with brotli compression
docker run -d --name nginx -p 80:80 ghcr.io/valksor/nginx:latest

# PostgreSQL 18 with persistent data
docker run -d --name postgres \
  -e POSTGRES_PASSWORD=mypassword \
  -v postgres_data:/var/lib/postgresql/data \
  ghcr.io/valksor/postgres:18

# cURL with HTTP/3 support
docker run --rm ghcr.io/valksor/curl:latest --version
```

## Available Images

### Base Images
| Image | Key Features | Use Case |
|-------|--------------|----------|
| **Debian** | Optimized base, no docs, custom user | Foundation for all images |

### PHP Variants (8.5.0-dev)
| Image | Key Features | Use Case |
|-------|--------------|----------|
| **php/fpm-base** | Core PHP 8.5.0-dev, minimal extensions | Base for PHP variants |
| **php/fpm** | GD, ImageMagick, Redis, MongoDB, APCu | Production PHP apps |
| **php/fpm-testing** | PCov, Xdebug, Composer, dev tools | Development & testing |
| **php/fpm-socket** | Unix socket (9000→/tmp/sockets/php-fpm.sock) | Local container comms |
| **php/fpm-testing-socket** | Socket + testing tools | Development with sockets |

### Web Services
| Image | Key Features | Use Case |
|-------|--------------|----------|
| **Nginx** | Brotli compression, optimized config | Web server, reverse proxy |
| **PostgreSQL** | Versions 17 & 18, backup scripts | Production database |

### Utilities
| Image | Key Features | Use Case |
|-------|--------------|----------|
| **cURL** | HTTP/3, QUIC, wolfSSL support | Modern HTTP requests |
| **action/split** | Git repo splitting, subtree operations | Monorepo management |

**Total: 11 optimized images**

## Usage Examples

### Base Images

Use the optimized Debian base as a foundation for custom images:

```bash
# Pull base image
docker pull ghcr.io/valksor/debian:latest

# Use in Dockerfile
FROM ghcr.io/valksor/debian:latest
```

### PHP Variants

Choose the right PHP variant for your needs:

```bash
# Production PHP with full extensions
docker run -d \
  --name php-app \
  -v /path/to/app:/var/www/html \
  ghcr.io/valksor/php/fpm:latest

# Development with testing tools
docker run -d \
  --name php-dev \
  -v /path/to/app:/var/www/html \
  ghcr.io/valksor/php/fpm-testing:latest

# PHP with Unix socket (for local container communication)
docker run -d \
  --name php-socket \
  -v /path/to/app:/var/www/html \
  ghcr.io/valksor/php/fpm-socket:latest

# Check PHP version and extensions
docker exec php-app php -v
docker exec php-app php -m
```

### Nginx

Deploy a high-performance web server with brotli compression:

```bash
# Run Nginx with custom config
docker run -d \
  --name web-server \
  -p 80:80 \
  -p 443:443 \
  -v /path/to/nginx.conf:/etc/nginx/nginx.conf \
  -v /path/to/html:/usr/share/nginx/html \
  valksor/nginx:latest

# Test brotli compression
curl -H "Accept-Encoding: br" -I http://localhost
```

### PostgreSQL

Run a secure, production-ready PostgreSQL database:

```bash
# Run PostgreSQL with persistent data
docker run -d \
  --name database \
  -e POSTGRES_PASSWORD=secure_password \
  -e POSTGRES_DB=myapp \
  -v postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  valksor/postgres:18

# Connect and test
docker exec -it database psql -U postgres -d myapp
```

### cURL

Use modern cURL with HTTP/3 and QUIC protocol support:

```bash
# Test HTTP/3 connectivity
docker run --rm ghcr.io/valksor/curl:latest \
  --http3 -I https://cloudflare.com

# Test with QUIC
docker run --rm ghcr.io/valksor/curl:latest \
  --http3 https://quic.rocks:443

# Check supported protocols
docker run --rm ghcr.io/valksor/curl:latest --version
```

### Action Split

Split monorepos into separate repositories using git subtree:

```bash
# Run action split utility
docker run --rm \
  -v /path/to/repo:/workspace \
  -e GITHUB_TOKEN=your_token \
  ghcr.io/valksor/action/split:latest

# Use in GitHub Actions
- uses: ghcr.io/valksor/action/split@latest
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
```

## Configuration

### Environment Variables

**PostgreSQL:**
- `POSTGRES_PASSWORD` - Required: database password
- `POSTGRES_USER` - Optional: default user (defaults to `postgres`)
- `POSTGRES_DB` - Optional: default database name

**Action Split:**
- `GITHUB_TOKEN` - Required: GitHub token for repository operations
- `COMPONENTS_FILE` - Optional: Path to components.json (defaults to `components.json`)

### Volume Mounting

```bash
# PHP application files
-v /host/path:/var/www/html

# Nginx configuration
-v /host/nginx.conf:/etc/nginx/nginx.conf

# PostgreSQL data persistence
-v postgres_data:/var/lib/postgresql/data

# Action Split repository workspace
-v /path/to/repo:/workspace
```

### Port Mapping

```bash
# Nginx web server
-p 80:80 -p 443:443

# PostgreSQL database
-p 5432:5432
```

## Performance & Security Benefits

### Optimized for Production
- **Minimal size**: All non-essential packages, docs, and locales removed
- **Native compilation**: Built with `-march=native` for optimal performance
- **Multi-arch support**: Available for x86_64 and ARM architectures

### Security Hardened
- **Non-root user**: Containers run as `valksor` user (UID/GID 1000)
- **Minimal attack surface**: Only necessary binaries and libraries included
- **Regular updates**: Built from latest security patches

### Performance Features
- **OPcache enabled** for PHP applications
- **Brotli compression** for Nginx
- **Connection pooling** and optimized PostgreSQL settings
- **Modern protocols** (HTTP/3, QUIC) in cURL

## Registry Information

### Image Registry
- **GitHub Container Registry**: `ghcr.io/valksor/*`

### Tagging Strategy
- `latest` - Most recent stable version (used for all images except PostgreSQL)
- `17`, `18` - PostgreSQL major versions (only images with version-specific tags)

### Pull Examples

```bash
# Base Images
docker pull ghcr.io/valksor/debian:latest

# PHP Variants
docker pull ghcr.io/valksor/php/fpm-base:latest
docker pull ghcr.io/valksor/php/fpm:latest
docker pull ghcr.io/valksor/php/fpm-testing:latest
docker pull ghcr.io/valksor/php/fpm-socket:latest
docker pull ghcr.io/valksor/php/fpm-testing-socket:latest

# Web Services
docker pull ghcr.io/valksor/nginx:latest
docker pull ghcr.io/valksor/postgres:17
docker pull ghcr.io/valksor/postgres:18

# Utilities
docker pull ghcr.io/valksor/curl:latest
docker pull ghcr.io/valksor/action/split:latest

```

## License

BSD 3-Clause License - see [LICENSE](LICENSE) file for details.
