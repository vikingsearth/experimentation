---
paths:
  - "src/mcp-registry/**"
---

# MCP Server Deployment & Operations

Standards S19–S20 from ADR-0002. Reference implementation: `src/mcp-registry/clickhouse-mcp/`.

## Deployment Stack (S19)

Every MCP server deploys with: **PM2 + nginx + Docker**.

### Docker

- Base image: `node:22-alpine` (from `ghcr.io/derivco/docker.io/`)
- **Multi-stage build**: builder stage (esbuild bundle via `npm run build:prod`) → production stage (prod deps only)
- Non-root user: UID/GID 10000 via `adduser`/`addgroup`
- Handle Netskope CA certificates in Dockerfile

### PM2 (`ecosystem.config.cjs`)

- `exec_mode: "fork"` — not cluster (MCP sessions are stateful, must stay on same process)
- `wait_ready: true` — app must call `process.send('ready')` after server is listening and resources initialized
- `listen_timeout: 10000` — wait up to 10s for ready signal
- `kill_timeout: 5000` — grace period before SIGKILL
- `error_file: "inherit"`, `out_file: "inherit"` — logs go to stdout/stderr for container log collection

```javascript
module.exports = {
  apps: [{
    name: "my-mcp",
    script: "./dist/index.js",
    instances: 1,
    exec_mode: "fork",
    wait_ready: true,
    listen_timeout: 10000,
    kill_timeout: 5000,
    error_file: "inherit",
    out_file: "inherit",
    env: { NODE_ENV: "production", PORT: 3920 },
  }],
};
```

### nginx

- Proxy from external port to PM2 internal port
- **SSE timeout handling**: `proxy_read_timeout 3600s`, `proxy_send_timeout 3600s` for long-lived SSE connections
- Disable buffering for `/mcp` route: `proxy_buffering off`, `proxy_cache off`
- Set `proxy_http_version 1.1` and `proxy_set_header Connection ''`
- Separate `/health` route for health checks

### Container Startup (`start.sh`)

```bash
#!/bin/sh
nginx &
exec pm2-runtime start ecosystem.config.cjs
```

### Canonical Deployment Files

```
Dockerfile              — Multi-stage: builder (esbuild) → prod (PM2+nginx)
ecosystem.config.cjs    — PM2 config (fork mode, wait_ready)
nginx.conf              — nginx main config (SSE timeouts)
default.conf            — nginx server block (proxy_pass to PM2)
start.sh                — Container CMD: nginx + PM2
```

## Graceful Shutdown (S20)

Implement a `shutdown(signal)` function registered on both `SIGTERM` (container orchestrator) and `SIGINT` (local dev):

1. Clear the cleanup interval
2. Set a forced shutdown timeout (configurable, default 30s) — calls `process.exit(1)` if graceful shutdown stalls
3. **Track open TCP sockets** via `server.on('connection', socket => sockets.add(socket))` — force-destroy after grace period
4. Close all active sessions (call `transport.close()` + `mcpInstance.close()` for each)
5. Close shared resources (database connections, HTTP clients)
6. Call `process.exit(0)`

```typescript
const sockets = new Set<net.Socket>();
httpServer.on("connection", (socket) => {
  sockets.add(socket);
  socket.on("close", () => sockets.delete(socket));
});

async function shutdown(signal: string) {
  clearInterval(cleanupInterval);
  const forceTimeout = setTimeout(() => process.exit(1),
    config.server.gracefulShutdownTimeoutMs);

  // Close all sessions
  for (const [id, session] of sessions.entries()) {
    sessions.delete(id);
    await session.transport.close();
    await session.mcpInstance.close();
  }

  // Destroy remaining sockets
  for (const socket of sockets) socket.destroy();

  // Close shared resources
  await manager.close();
  httpServer.close(() => process.exit(0));
  clearTimeout(forceTimeout);
}

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));
```
