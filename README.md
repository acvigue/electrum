# Electrum Docker

A secure, multi-architecture Docker image for running [Electrum](https://electrum.org/) Bitcoin wallet as a daemon with RPC interface.

## Features

- 🔒 **Security First**: Runs as non-root user (UID/GID 521)
- 🏗️ **Multi-Architecture**: Supports amd64, arm64, arm, and more
- 🔧 **S6-Overlay**: Proper process supervision and graceful shutdown
- 🌐 **Network Support**: Mainnet, Testnet, and other networks
- 🔌 **RPC Interface**: Full JSON-RPC API access
- 🔄 **Auto-Recovery**: Handles stale lockfiles and daemon restart
- 📦 **Minimal Size**: Optimized Alpine-based image

## Quick Start

### Prerequisites

- Docker
- Docker Compose (optional)
- `electrum-key.asc` file (ThomasV's GPG public key)

### Build the Image

```bash
docker build -t electrum:latest .
```

### Run with Docker

```bash
docker run -d \
  --name electrum \
  -p 7000:7000 \
  -v $(pwd)/data:/data \
  -e ELECTRUM_RPC_USERNAME=electrum \
  -e ELECTRUM_RPC_PASSWORD=your_secure_password \
  electrum:latest
```

### Run with Docker Compose

```bash
docker-compose up -d
```

## Configuration

### Environment Variables

| Variable                | Default          | Description                                    |
| ----------------------- | ---------------- | ---------------------------------------------- |
| `ELECTRUM_RPC_HOST`     | `0.0.0.0`        | RPC server bind address                        |
| `ELECTRUM_RPC_PORT`     | `7000`           | RPC server port                                |
| `ELECTRUM_RPC_USERNAME` | `""`             | RPC authentication username                    |
| `ELECTRUM_RPC_PASSWORD` | `""`             | RPC authentication password                    |
| `TESTNET`               | `false`          | Enable testnet mode (`true` or `false`)        |
| `ELECTRUM_NETWORK`      | `mainnet`        | Network to use (mainnet, testnet, etc.)        |
| `ELECTRUM_WALLET_NAME`  | `default_wallet` | Name of the wallet file                        |
| `ELECTRUM_PROXY`        | `""`             | Proxy configuration (e.g., `socks5:host:port`) |
| `PUID`                  | `521`            | User ID for running the daemon                 |
| `PGID`                  | `521`            | Group ID for running the daemon                |

### Volume Mounts

- `/data` - Electrum data directory containing wallets and configuration

## Usage

### Creating a Wallet

```bash
# Standard wallet
docker exec -it electrum electrum -D /data/.electrum create -w /data/.electrum/wallets/my_wallet

# Testnet wallet
docker exec -it electrum electrum --testnet -D /data/.electrum/testnet create -w /data/.electrum/testnet/wallets/testnet_wallet
```

### Loading a Wallet

Wallets are automatically loaded on startup if they exist at the configured path. To manually load:

```bash
docker exec -it electrum electrum -D /data/.electrum load_wallet -w /data/.electrum/wallets/my_wallet
```

### RPC Commands

```bash
# Get wallet info
curl --user electrum:your_password \
  --data-binary '{"jsonrpc":"2.0","id":"1","method":"getinfo","params":[]}' \
  http://localhost:7000

# Get balance
curl --user electrum:your_password \
  --data-binary '{"jsonrpc":"2.0","id":"1","method":"getbalance","params":[]}' \
  http://localhost:7000

# Get new address
curl --user electrum:your_password \
  --data-binary '{"jsonrpc":"2.0","id":"1","method":"getunusedaddress","params":[]}' \
  http://localhost:7000
```

### Interactive Commands

```bash
# Access Electrum CLI
docker exec -it electrum electrum -D /data/.electrum getinfo

# List wallets
docker exec -it electrum electrum -D /data/.electrum list_wallets

# Get balance
docker exec -it electrum electrum -D /data/.electrum getbalance
```

## File Structure

```
.
├── Dockerfile                  # Main Docker image definition
├── docker-compose.yml         # Docker Compose configuration
├── electrum-key.asc          # ThomasV's GPG public key
├── electrum-daemon-run       # S6 service run script
├── electrum-daemon-finish    # S6 service finish script
├── run-electrum.sh           # Main startup script
├── healthcheck.sh            # Docker healthcheck script
└── data/                     # Wallet data directory (created on first run)
    └── .electrum/
        ├── wallets/          # Wallet files
        ├── certs/            # SSL certificates
        └── config           # Electrum configuration
```

## Security Considerations

### RPC Authentication

**Always** set strong `ELECTRUM_RPC_USERNAME` and `ELECTRUM_RPC_PASSWORD` values. Never use default or empty passwords in production.

### Network Exposure

- Only expose RPC port (`7000`) to trusted networks
- Consider using a reverse proxy with SSL/TLS for remote access
- Use firewall rules to restrict access

### Wallet Security

- Store wallet files securely with proper backups
- Use encrypted wallets with strong passwords
- Never commit wallet files or seeds to version control

### User Permissions

The container runs as UID/GID 521. Ensure your volume mounts have appropriate permissions:

```bash
# Set ownership on host
sudo chown -R 521:521 ./data

# Or match your host user
docker run -e PUID=$(id -u) -e PGID=$(id -g) ...
```

## Testnet Configuration

To run on testnet, set `TESTNET=true`:

```yaml
environment:
  - TESTNET=true
  - ELECTRUM_WALLET_NAME=testnet_wallet
```

## Proxy Configuration

To use Electrum over Tor or other SOCKS proxy:

```yaml
environment:
  - ELECTRUM_PROXY=socks5:127.0.0.1:9050
```

## Troubleshooting

### Daemon won't start

```bash
# Check logs
docker logs electrum

# Check if lockfile exists
docker exec electrum ls -la /data/.electrum/daemon

# Manually remove lockfile if stale
docker exec electrum rm -f /data/.electrum/daemon
```

### Permission errors

```bash
# Fix volume permissions
sudo chown -R 521:521 ./data

# Or use your user ID
docker run -e PUID=$(id -u) -e PGID=$(id -g) ...
```

### Connection issues

```bash
# Test daemon is running
docker exec electrum electrum -D /data/.electrum getinfo

# Check network connectivity
docker exec electrum electrum -D /data/.electrum getservers
```

## Building for Multiple Architectures

```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1

# Build for specific architecture
docker buildx build --platform linux/amd64,linux/arm64 -t electrum:latest .

# Build and push to registry
docker buildx build --platform linux/amd64,linux/arm64 -t myregistry/electrum:latest --push .
```

## Updating Electrum

To update to a new version of Electrum:

1. Modify `ARG ELECTRUM_VERSION` in the Dockerfile
2. Rebuild the image: `docker-compose build`
3. Restart the container: `docker-compose up -d`

## License

This Docker configuration is provided as-is. Electrum itself is licensed under the MIT License.

## Contributing

Contributions are welcome! Please ensure:

- Security best practices are maintained
- Non-root user execution is preserved
- Multi-architecture support continues to work

## References

- [Electrum Official Website](https://electrum.org/)
- [Electrum Documentation](https://electrum.readthedocs.io/)
- [Electrum GitHub](https://github.com/spesmilo/electrum)
- [S6 Overlay](https://github.com/just-containers/s6-overlay)
