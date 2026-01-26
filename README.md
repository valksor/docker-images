# Valksor Docker Images

[![valksor](https://badgen.net/static/org/valksor/green)](https://github.com/valksor)
[![BSD-3-Clause](https://img.shields.io/badge/BSD--3--Clause-green?style=flat)](https://github.com/valksor/docker-images/blob/master/LICENSE)

Production-ready, highly optimized Docker images for modern web applications. Built by SIA Valksor with focus on performance, security, and minimal size.

Available images: **Base Images**, **PHP-FPM variants**, **PHP-ZTS variants**, **FrankenPHP**, **Nginx**, **PostgreSQL**, **cURL**, **Action utilities**, and more.

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

# FrankenPHP application server
docker run -d --name frankenphp -p 80:80 ghcr.io/valksor/php/franken:latest
```

## Available Images

### Base Images
| Image | Key Features | Use Case |
|-------|--------------|----------|
| **Debian** | Optimized base, no docs, custom user | Foundation for all images |

### PHP-FPM Variants (8.5.0-dev)
| Image | Key Features | Use Case |
|-------|--------------|----------|
| **php/fpm-base** | Core PHP 8.5.0-dev, minimal extensions | Base for PHP-FPM variants |
| **php/fpm** | GD, ImageMagick, Redis, MongoDB, APCu, gRPC, Protobuf | Production PHP apps |
| **php/fpm-testing** | PCov, Xdebug, Composer, dev tools | Development & testing |
| **php/fpm-socket** | Unix socket (9000→/tmp/sockets/php-fpm.sock) | Local container comms |
| **php/fpm-testing-socket** | Socket + testing tools | Development with sockets |

### PHP-ZTS Variants (8.5.0-dev)
| Image | Key Features | Use Case |
|-------|--------------|----------|
| **php/zts-base** | Thread-safe PHP base, embed SAPI | Base for ZTS variants |
| **php/zts** | ZTS with extensions (GD, Redis, gRPC, Protobuf) | Multi-threaded PHP apps |
| **php/zts-testing** | ZTS + Xdebug, PCov, Composer | Thread-safe development |

### FrankenPHP Variants (8.5.0-dev)
| Image | Key Features | Use Case |
|-------|--------------|----------|
| **php/franken** | Go-based PHP server, HTTP/3, Mercure, Vulcain | Modern application server |
| **php/franken-testing** | FrankenPHP + Xdebug, PCov | Development with FrankenPHP |

### PHP Master Branch (8.6.0-dev)
All PHP variants are available with the `:master` tag for testing PHP 8.6.0-dev:
```bash
ghcr.io/valksor/php/fpm:master
ghcr.io/valksor/php/zts:master
ghcr.io/valksor/php/franken:master
```

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

**Total: 25 optimized images**

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

### PHP-ZTS Variants

Thread-safe PHP for parallel execution and embedded applications:

```bash
# Thread-safe PHP for parallel execution
docker run -d \
  --name php-zts-app \
  -v /path/to/app:/var/www/html \
  ghcr.io/valksor/php/zts:latest

# ZTS with testing tools
docker run -d \
  --name php-zts-dev \
  -v /path/to/app:/var/www/html \
  ghcr.io/valksor/php/zts-testing:latest

# Interactive mode (ZTS uses CLI by default)
docker run -it --rm ghcr.io/valksor/php/zts:latest php -a
```

### FrankenPHP

Modern Go-based PHP application server with built-in HTTP/3, Mercure, and Vulcain:

```bash
# FrankenPHP with built-in web server
docker run -d \
  --name frankenphp-app \
  -p 80:80 \
  -p 443:443 \
  -v /path/to/app:/var/www/html \
  ghcr.io/valksor/php/franken:latest

# FrankenPHP with custom Caddyfile
docker run -d \
  --name frankenphp-custom \
  -p 80:80 \
  -v /path/to/Caddyfile:/etc/caddy/Caddyfile \
  -v /path/to/app:/var/www/html \
  ghcr.io/valksor/php/franken:latest

# Development with Xdebug
docker run -d \
  --name frankenphp-dev \
  -p 80:80 \
  -v /path/to/app:/var/www/html \
  ghcr.io/valksor/php/franken-testing:latest

# Check FrankenPHP version
docker exec frankenphp-app frankenphp version
```

### PHP Master Branch (8.6.0-dev)

Test upcoming PHP features using the master branch builds:

```bash
# Test PHP 8.6.0-dev with FPM
docker run --rm ghcr.io/valksor/php/fpm:master php -v

# Test with FrankenPHP
docker run --rm ghcr.io/valksor/php/franken:master php -v

# Development with master branch
docker run -d \
  --name php-master-dev \
  -v /path/to/app:/var/www/html \
  ghcr.io/valksor/php/fpm-testing:master
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
  ghcr.io/valksor/nginx:latest

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
  ghcr.io/valksor/postgres:18

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

**FrankenPHP:**
- `XDG_CONFIG_HOME` - Config directory (defaults to `/config`)
- `XDG_DATA_HOME` - Data directory (defaults to `/data`)

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

# FrankenPHP Caddyfile
-v /host/Caddyfile:/etc/caddy/Caddyfile

# Caddy data and certificates
-v caddy_data:/data
-v caddy_config:/config
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
- **Multi-architecture support**: Available for x86_64 and ARM64/Apple Silicon

### Multi-Architecture Support
All images are built for:
- `linux/amd64` (x86_64)
- `linux/arm64` (ARM64/Apple Silicon)

### Security Hardened
- **Non-root user**: Containers run as `valksor` user (UID/GID 1000)
- **Minimal attack surface**: Only necessary binaries and libraries included
- **Regular updates**: Built from latest security patches

### Performance Features
- **OPcache enabled** for PHP applications
- **Brotli compression** for Nginx
- **Connection pooling** and optimized PostgreSQL settings
- **Modern protocols** (HTTP/3, QUIC) in cURL
- **Thread-safe execution** (ZTS variants for parallel processing)
- **Embedded SAPI** for ZTS variants
- **HTTP/3 and QUIC support** in FrankenPHP
- **Built-in Caddy web server** with automatic HTTPS (FrankenPHP)

## Registry Information

### Image Registry
- **GitHub Container Registry**: `ghcr.io/valksor/*`

### Tagging Strategy
- `latest` - Most recent stable version (PHP 8.5.0-dev)
- `master` - PHP 8.6.0-dev development branch
- `17`, `18` - PostgreSQL major versions

### Pull Examples

```bash
# Base Images
docker pull ghcr.io/valksor/debian:latest

# PHP-FPM Variants
docker pull ghcr.io/valksor/php/fpm-base:latest
docker pull ghcr.io/valksor/php/fpm:latest
docker pull ghcr.io/valksor/php/fpm-testing:latest
docker pull ghcr.io/valksor/php/fpm-socket:latest
docker pull ghcr.io/valksor/php/fpm-testing-socket:latest

# PHP-ZTS Variants
docker pull ghcr.io/valksor/php/zts-base:latest
docker pull ghcr.io/valksor/php/zts:latest
docker pull ghcr.io/valksor/php/zts-testing:latest

# FrankenPHP Variants
docker pull ghcr.io/valksor/php/franken:latest
docker pull ghcr.io/valksor/php/franken-testing:latest

# PHP Master Branch (8.6.0-dev)
docker pull ghcr.io/valksor/php/fpm:master
docker pull ghcr.io/valksor/php/fpm-testing:master
docker pull ghcr.io/valksor/php/zts:master
docker pull ghcr.io/valksor/php/franken:master

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
