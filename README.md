# Mailloop for AI agents

Email-testing skills and tools for AI agents. Published as the standalone public
repo **`mailloop/skills`**. The design is deliberately **unified**: there is

- **one MCP server** — `https://api.mailloop.io/mcp` (the only real integration), and
- **one canonical skill** — [`skills/mailloop/SKILL.md`](skills/mailloop/SKILL.md)
  (the single source of truth for the playbook).

Everything else is just a thin wrapper around those two: the Claude Code plugin
bundles them, and `AGENTS.md` is generated from the skill for agents that don't
read the Agent Skills format. **You maintain the skill in one place.**

## The one MCP server

Streamable HTTP, `https://api.mailloop.io/mcp`. Two ways to authenticate:

- **OAuth** (browser consent) — point any MCP client at the URL with no auth
  header; approve org + scopes in the browser. No key to manage.
- **API key** (headless / CI) — `Authorization: Bearer $MAILLOOP_API_KEY`
  (create one under **Settings → Organization → API keys**).

```jsonc
{
  "mcpServers": {
    "mailloop": { "type": "http", "url": "https://api.mailloop.io/mcp" }
  }
}
```

That JSON is the *same everywhere* — only the file it lives in changes per agent
(see the table). For an API key, add `"headers": { "Authorization": "Bearer ${MAILLOOP_API_KEY}" }`.

## Install per agent

| Agent | Add the MCP server | Add the skill |
|-------|--------------------|---------------|
| **Claude Code** | bundled in the plugin | bundled in the plugin |
| **OpenCode** | `opencode.json` → `mcp` | copy `skills/mailloop/` into its skills dir (native `SKILL.md`, lazy-loaded) |
| **Cline** | `cline_mcp_settings.json` | copy `skills/mailloop/` (native Agent Skills, lazy-loaded) |
| **Cursor** | `.cursor/mcp.json` | use `AGENTS.md`, or a `.cursor/rules/*.mdc` set to *Agent Requested* |
| **Goose / other MCP agents** | that agent's MCP config | drop `AGENTS.md` at the project root (always-on) |

**Claude Code** (gets both in one step):

```
/plugin marketplace add mailloop/skills
/plugin install mailloop@mailloop
```

**Any other MCP agent** (manual, e.g. via the CLI form):

```bash
# OAuth
claude mcp add --transport http mailloop https://api.mailloop.io/mcp
# or with an API key
claude mcp add --transport http mailloop https://api.mailloop.io/mcp \
  --header "Authorization: Bearer $MAILLOOP_API_KEY"
```

…then give the agent the playbook: either copy the `skills/mailloop/` folder (if
it supports the Agent Skills `SKILL.md` format — lazy-loaded, token-cheap) or use
the always-on `AGENTS.md`.

## Editing the playbook

`skills/mailloop/SKILL.md` is the **single source of truth**. The Claude plugin
reads it via symlink, and `AGENTS.md` is generated from it:

```bash
# edit skills/mailloop/SKILL.md, then regenerate the always-on copy:
bash scripts/build-agents-md.sh
```

## Local development

The shipped plugin always points at production. To test against a local Mailloop
stack (API on `:4002`, web/auth-server on `:4000`) **without touching the shipped
files**, use the separate `local-dev/` marketplace — a parallel, gitignored
marketplace whose `mailloop-local` plugin targets `http://localhost:4002/mcp` and
symlinks the **same** canonical skill.

```
/plugin marketplace add /absolute/path/to/skills/local-dev
/plugin install mailloop-local@mailloop-local
```

Because `local-dev/` is gitignored, it can never be committed or published — no
swapping, no risk of shipping the localhost URL. (Env-var URLs aren't an option:
`${VAR}` expansion is unreliable inside a plugin's `.mcp.json`.)

## Layout

```
skills/mailloop/SKILL.md             # ← canonical skill (single source of truth)
AGENTS.md                            # generated from the skill (always-on fallback)
scripts/build-agents-md.sh           # regenerates AGENTS.md from the skill
.gitignore                           # ignores local-dev/

.claude-plugin/marketplace.json      # Claude Code marketplace (production)
plugins/mailloop/
├── .claude-plugin/plugin.json       # plugin manifest
├── .mcp.json                        # the one MCP server (production URL)
└── skills/mailloop  ->  ../../../skills/mailloop      # symlink to canonical

local-dev/                           # gitignored — local testing only
└── plugins/mailloop-local/
    ├── .mcp.json                    # url: http://localhost:4002/mcp
    └── skills/mailloop  ->  ../../../../skills/mailloop   # symlink to canonical
```

## Scopes

The MCP tools enforce these API-key scopes: `sandboxes:read`, `sandboxes:write`,
`emails:read`, `webhooks:read`, `webhooks:write`. A key with `*` has full access.

Full docs: https://mailloop.io/mcp
