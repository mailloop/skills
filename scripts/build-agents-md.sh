#!/usr/bin/env bash
#
# Single source of truth: skills/mailloop/SKILL.md.
# This regenerates AGENTS.md (the always-on fallback for agents that don't
# support the Agent Skills / SKILL.md format — Goose, generic MCP agents, etc.)
# by prepending an MCP-connection preamble to the skill body.
#
# Run after editing the skill:  bash scripts/build-agents-md.sh
set -euo pipefail
cd "$(dirname "$0")/.."

SKILL="skills/mailloop/SKILL.md"
OUT="AGENTS.md"

# Strip the YAML frontmatter (everything up to and including the 2nd '---'),
# keep the playbook body.
body="$(awk 'BEGIN{n=0} /^---[[:space:]]*$/{n++; next} n>=2{print}' "$SKILL")"

cat > "$OUT" <<EOF
<!-- GENERATED FROM skills/mailloop/SKILL.md — edit that file, then run scripts/build-agents-md.sh -->

# Mailloop

Email-testing tools for AI agents, exposed over a single MCP server.

## Connect the MCP server (one endpoint, any MCP-capable agent)

Streamable HTTP — \`https://api.mailloop.io/mcp\`. Authenticate one of two ways:

- **OAuth** (browser consent): point your agent's MCP config at the URL with no
  auth header; it runs the OAuth flow and you approve org + scopes in a browser.
- **API key** (headless/CI): send \`Authorization: Bearer \$MAILLOOP_API_KEY\`
  (create a key under Settings → Organization → API keys).

\`\`\`jsonc
{
  "mcpServers": {
    "mailloop": { "type": "http", "url": "https://api.mailloop.io/mcp" }
  }
}
\`\`\`

The playbook below tells you how to drive the tools that server exposes.

---
$body
EOF

echo "Wrote $OUT from $SKILL"
