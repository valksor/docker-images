# Valksor Docker Images

[![valksor](https://badgen.net/static/org/valksor/green)](https://github.com/valksor)
[![BSD-3-Clause](https://img.shields.io/badge/BSD--3--Clause-green?style=flat)](https://github.com/valksor/docker-images/blob/master/LICENSE)

Production-ready, highly optimized Docker images for modern web applications. Built by SIA Valksor with focus on performance, security, and minimal size.

Available images: **Base Images**, **PHP-ZTS variants**, **FrankenPHP**, **Nginx**, **PostgreSQL**, **cURL**, **Action utilities**, and more.

## Quick Start

Pull and run any image in seconds:

```bash
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
docker run -d --name frankenphp -p 80:80 ghcr.io/valksor/php/franken:master
```

## Available Images

### Base Images
| Image | Key Features | Use Case |
|-------|--------------|----------|
| **Debian** | Optimized base, no docs, custom user | Foundation for all images |

### PHP-ZTS Variants (8.6.0-dev, `:master` tag)
| Image | Key Features | Use Case |
|-------|--------------|----------|
| **php/zts-base** | Thread-safe PHP base, embed SAPI | Base for ZTS variants |
| **php/zts** | ZTS with extensions (GD, Redis, gRPC, Protobuf) | Multi-threaded PHP apps |
| **php/zts-testing** | ZTS + Xdebug, PCov, Composer | Thread-safe development |

### FrankenPHP Variants (8.6.0-dev, `:master` tag)
| Image | Key Features | Use Case |
|-------|--------------|----------|
| **php/franken** | Go-based PHP server, HTTP/3, Mercure, Vulcain | Modern application server |
| **php/franken-testing** | FrankenPHP + Xdebug, PCov | Development with FrankenPHP |

### Web Services
| Image | Key Features | Use Case |
|-------|--------------|----------|
| **Nginx** | Brotli compression, optimized config | Web server, reverse proxy |
| **PostgreSQL** | Version 18, backup scripts | Production database |

### Utilities
| Image | Key Features | Use Case |
|-------|--------------|----------|
| **cURL** | HTTP/3, QUIC, wolfSSL support | Modern HTTP requests |
| **action/split** | Git repo splitting, subtree operations | Monorepo management |

**Total: 10 optimized images**

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

Note: the `sodium` extension is loaded by default; derived images that enable `sodium` themselves should drop that line (the image already ships `conf.d/docker-php-ext-sodium.ini`) to avoid a "Module already loaded" warning. `pecl`/`pear` are no longer shipped (PEAR/PECL are deprecated); to add an extension, switch to `USER root` and run `apt-get update && apt-get install -y build-essential autoconf` first (package lists are removed in the images), then either run `phpize && ./configure && make install` from the extension source or use [PIE](https://github.com/php/pie), the PHP Installer for Extensions, and in both cases switch back to `USER valksor`.

PHP image notes:

- `php -a` and the `readline` functions use libedit, like the official PHP images. Configure line editing in `~/.editrc` (not `~/.inputrc`); some `readline_*` functions behave differently under libedit, see the [readline documentation](https://www.php.net/manual/en/book.readline.php).
- `/usr/local/bin` is writable only by root (tools remain executable by everyone). Install your own tools as root in a derived image, or into a directory you own and add to `PATH`.
- Licensing: this repo is BSD-3-Clause, except the vendored files under `php/docker` (MIT, Docker, Inc.). The image license label (`BSD-3-Clause AND MIT`) covers this repo's files, including those vendored MIT files, not the bundled PHP runtime or other software: the runtime is BSD-3-Clause on the master/8.6 branch, and its license ships in the image at `/usr/local/share/doc/php/LICENSE`; extension licenses ship under `/usr/local/share/doc/php-ext/`. Other bundled software keeps its own license.

### PHP-ZTS Variants

Thread-safe PHP for parallel execution and embedded applications:

```bash
# Thread-safe PHP for parallel execution
docker run -d \
  --name php-zts-app \
  -v /path/to/app:/var/www/html \
  ghcr.io/valksor/php/zts:master

# ZTS with testing tools
docker run -d \
  --name php-zts-dev \
  -v /path/to/app:/var/www/html \
  ghcr.io/valksor/php/zts-testing:master

# Interactive mode (ZTS uses CLI by default)
docker run -it --rm ghcr.io/valksor/php/zts:master php -a
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
  ghcr.io/valksor/php/franken:master

# FrankenPHP with custom Caddyfile
docker run -d \
  --name frankenphp-custom \
  -p 80:80 \
  -v /path/to/Caddyfile:/etc/caddy/Caddyfile \
  -v /path/to/app:/var/www/html \
  ghcr.io/valksor/php/franken:master

# Development with Xdebug
docker run -d \
  --name frankenphp-dev \
  -p 80:80 \
  -v /path/to/app:/var/www/html \
  ghcr.io/valksor/php/franken-testing:master

# Check FrankenPHP version
docker exec frankenphp-app frankenphp version
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

Split a monorepo into separate destination repositories using git subtree. Each
component in `components.json` names a destination `repo` URL; any `NAME@`
placeholder in that URL is replaced with the value of the environment variable
`NAME`, so different components can push behind different tokens. Only env-var
names listed in the required `ALLOWED_ENVS` allowlist may be substituted.

```yaml
# Use in GitHub Actions
- name: Split
  uses: docker://ghcr.io/valksor/action/split:latest
  env:
    REPO:   ${{ github.repository }}
    BRANCH: ${{ steps.branch.outputs.branch }}
    GH_TOKEN:     ${{ secrets.GH_TOKEN }}
    GH_TOKEN_PKG: ${{ secrets.GH_TOKEN_PKG }}
    ALLOWED_ENVS: GH_TOKEN GH_TOKEN_PKG
    COMPONENTS_JSON_PATH: .github/deploy/components.json
```

`components.json` (note the required `https://` scheme):

```json
[
  { "path": "pkg/a", "repo": "https://GH_TOKEN@github.com/org/a.git" },
  { "path": "pkg/b", "repo": "https://GH_TOKEN_PKG@github.com/org/b.git" }
]
```

**Security note:** substituted values are embedded as HTTPS Basic-Auth in the
push URL, so `components.json` (especially when fetched via `COMPONENTS_JSON_URL`,
which is not integrity-checked) must come from a trusted source. The required
`ALLOWED_ENVS` allowlist bounds which env vars may ever be substituted.

## Configuration

### Environment Variables

**PostgreSQL:**
- `POSTGRES_PASSWORD` - Required: database password
- `POSTGRES_USER` - Optional: default user (defaults to `postgres`)
- `POSTGRES_DB` - Optional: default database name

**Action Split:**
- `REPO` - Required: source repo `owner/name`
- `BRANCH` - Required: source branch
- `ALLOWED_ENVS` - Required: space-separated allowlist of env names that may be substituted into `NAME@` placeholders
- `GH_TOKEN` - Optional: authenticates the source clone; also substituted into a `GH_TOKEN@` placeholder when listed in `ALLOWED_ENVS`
- Any `NAME@` placeholder in a component's `repo` URL is replaced by `$NAME`, provided `NAME` is in `ALLOWED_ENVS`; a referenced env that is not allowlisted, unset, or empty is a hard error
- `COMPONENTS_JSON_PATH` - Optional: path to components.json (defaults to `.github/deploy/components.json`; positional arg `$1`)
- `COMPONENTS_JSON_URL` - Optional: fallback URL if the path is missing (positional arg `$2`)

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
- **Multi-architecture support**: ARM64/Apple Silicon by default; x86_64 built on request

### Multi-Architecture Support
Images are published as manifests covering:
- `linux/arm64` (ARM64/Apple Silicon) — always built
- `linux/amd64` (x86_64) — built on request; the build workflow defaults to arm64 only

### Security Hardened
- **Non-root user**: Most containers run as the `valksor` user (UID/GID 1000); service images run as their dedicated user (e.g. PostgreSQL runs as `postgres`, starting as root only to drop privileges via gosu)
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
- `latest` - Most recent stable version
- `master` - PHP 8.6.0-dev development branch
- `18` - PostgreSQL major version

The PHP-FPM images are removed (migrate to the ZTS or FrankenPHP images); the ZTS/FrankenPHP `:latest` tags are frozen — switch to their `:master` tags.

### Pull Examples

```bash
# Base Images
docker pull ghcr.io/valksor/debian:latest

# PHP Variants (8.6.0-dev, `:master` tag)
docker pull ghcr.io/valksor/php/zts-base:master
docker pull ghcr.io/valksor/php/zts:master
docker pull ghcr.io/valksor/php/zts-testing:master
docker pull ghcr.io/valksor/php/franken:master
docker pull ghcr.io/valksor/php/franken-testing:master

# Web Services
docker pull ghcr.io/valksor/nginx:latest
docker pull ghcr.io/valksor/postgres:18

# Utilities
docker pull ghcr.io/valksor/curl:latest
docker pull ghcr.io/valksor/action/split:latest
```

## License

BSD 3-Clause License - see [LICENSE](LICENSE) file for details.
