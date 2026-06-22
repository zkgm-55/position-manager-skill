# position-manager-skill

A Claude Code / agentic-coding skill for managing Solana CLMM (concentrated
liquidity) positions across Orca Whirlpools, Raydium CLMM, and Meteora DLMM.

Submitted for the Solana AI Kit community bounty (Superteam Brasil), leveling
up the position-manager-skill seed idea to production grade.

## Table of contents

- [The problem](#the-problem)
- [What this skill does](#what-this-skill-does)
- [Why this design](#why-this-design)
- [Structure](#structure)
- [Install](#install)
- [Manual install](#manual-install)
- [Example usage](#example-usage)
- [Scope and limitations](#scope-and-limitations)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [License](#license)
- [Contributing](#contributing)

## The problem

Concentrated liquidity positions lose money silently. When price moves outside
a position range, fee accrual stops completely, but most LPs do not notice
until they check manually, by which point they have been earning nothing for
days.

The problem compounds across protocols. A DeFi builder active on Orca,
Raydium, and Meteora simultaneously has no single view of position health.
Each protocol has its own dashboard, its own terminology, and its own way of
reporting range status. Checking all three manually every day is friction
most people skip — until it's too late.

Nobody in the current Solana agent-skill ecosystem has a cross-protocol
position health checker. Every existing tool is single-protocol, and most
require a full SDK install that does not fit lean or mobile build environments.

## What this skill does

Given a wallet address (or a specific position), this skill:

1. Finds open LP positions across Orca Whirlpools, Raydium CLMM, and Meteora DLMM
2. Reports in-range or out-of-range status for each, with which direction price moved
3. Estimates impermanent loss and fee yield, net of each other
4. Flags positions near the edge of their range before they go out-of-range
5. Suggests, never executes, rebalancing options, framed as a tradeoff rather than a directive

This skill is read-only. It never constructs, signs, or sends transactions,
and never handles private keys. It is an analysis and decision-support tool,
not a trading bot.

## Why this design

- **Progressive disclosure** — the main SKILL.md is a router. Detailed
  protocol API specs, math formulas, and rebalancing logic live in separate
  reference files, loaded only when the task needs them.
- **REST API first, RPC fallback** — each protocol public REST API is used by
  default for speed and simplicity. If an API is down, rate-limited, or does
  not index a position, the skill falls back to direct Solana RPC account
  parsing (skill/rpc-fallback.md).
- **No SDK dependency required** — works in constrained environments such as
  mobile or Termux where installing full protocol SDKs is not practical.
- **Honesty over confidence** — every reference file explicitly instructs
  against fabricating numbers when data is missing or an API or RPC call fails.

## Structure

```

position-manager-skill/
├── README.md
├── LICENSE
├── install.sh
└── skill/
    ├── SKILL.md                     entry point / router
    ├── protocols.md                 Orca, Raydium, Meteora API + account specs
    ├── analysis.md                  IL estimation, fee yield, range proximity
    ├── rebalancing.md               rebalance option generation (read-only)
    ├── rpc-fallback.md              direct RPC parsing when REST APIs fail
    └── resources.md                 curated links and reference docs
agents/
    └── position-health-checker.md   optional agent persona
commands/
    └── check-positions.md           slash command definition
```

SKILL.md is the only file loaded at startup. Sub-files are pulled in only
when the routing table in SKILL.md determines they are needed for the current
request. This keeps context usage low for simple queries.

## Install

```bash
git clone https://github.com/zkgm-55/position-manager-skill.git
cd position-manager-skill
./install.sh
```

This copies `skill/` into your project `.claude/skills/position-manager-skill/`
directory. No build step, no dependencies beyond standard fetch or curl plus
JSON parsing.

## Manual install

If you prefer not to run `install.sh`, or you are integrating this into a
custom agent setup, copy the files yourself:

```bash
# 1. Clone the repo
git clone https://github.com/zkgm-55/position-manager-skill.git
cd position-manager-skill

# 2. Create the target directory
mkdir -p ~/.claude/skills/position-manager-skill

# 3. Copy skill/ contents into it
cp -r skill/* ~/.claude/skills/position-manager-skill/

# 4. Confirm the entry point is in place
ls ~/.claude/skills/position-manager-skill/SKILL.md
```

No build step required. To uninstall:

```bash
rm -rf ~/.claude/skills/position-manager-skill
```

To use as a submodule in an existing Solana AI Kit checkout:

```bash
git submodule add https://github.com/zkgm-55/position-manager-skill.git skills/position-manager
```

## Example usage

Once installed, the skill triggers automatically on relevant requests:

**Checking all positions on a wallet:**
```
"Check my LP positions on wallet <address>"
→ scans Orca, Raydium, and Meteora for open positions
→ returns range status, IL estimate, and fee yield for each
```

**Protocol-specific queries:**
```
"Is my Whirlpool SOL/USDC position still in range?"
→ routes to protocols.md (Orca section)
→ fetches current price vs position tick bounds

"What's my impermanent loss on Raydium position <address>?"
→ routes to analysis.md
→ estimates IL using entry price vs current price delta

"Should I rebalance my Meteora DLMM position?"
→ routes to rebalancing.md
→ presents options with tradeoffs, never executes
```

**Near-edge warning:**
```
"Alert me if any position is close to going out of range"
→ checks proximity to upper/lower tick bounds across all protocols
→ flags positions within a configurable threshold (default 5% of range width)
```

The skill will ask for a wallet address or position address the first time
it needs on-chain data — it does not store or assume any address.

## Scope and limitations

- **Read-only** — does not execute swaps, opens, closes, or rebalances.
- **IL estimates are directional approximations**, not precise accounting.
  Entry price is inferred from position data when not explicitly provided,
  which introduces error on older positions.
- **Public protocol APIs are unofficial and rate-limited** — pair with a
  dedicated RPC provider (Helius, Triton, etc.) for high-frequency monitoring.
- **Meteora DLMM bin logic** differs from standard CLMM tick math — the skill
  handles this separately in protocols.md but the approximation is less precise
  than for Orca and Raydium.

## Troubleshooting

**No positions found for my wallet.**
The public REST APIs index positions with a delay after opening. If a position
was opened very recently (within the last few minutes), try again shortly or
use the RPC fallback path described in skill/rpc-fallback.md.

**IL estimate looks wrong.**
IL estimation requires knowing the entry price of the position. If this cannot
be inferred from on-chain data, the skill will ask for it explicitly. Providing
the actual entry price improves accuracy significantly.

**API call failed or returned empty data.**
This is usually a rate limit on the public protocol REST API. The skill
automatically falls back to direct RPC parsing (rpc-fallback.md) when this
happens. If both fail, the skill will say so rather than guessing.

**Position shows out-of-range but I can see it is in range on the dashboard.**
Price data from the REST API and the dashboard may have a few seconds of lag
difference. Wait a moment and retry, or check the RPC fallback path for a
fresher reading.

## FAQ

**Does this skill ever send transactions or move funds?**
No. It is strictly read-only — analysis and suggestions only. No wallet
connection, no signing, no execution of any kind.

**Can I use this without a dedicated RPC endpoint?**
Yes. The skill defaults to public protocol REST APIs which require no RPC
setup. A dedicated RPC endpoint (Helius, Triton, etc.) is only needed if you
want fresher data or are running high-frequency checks that hit public rate
limits.

**Does it support protocols other than Orca, Raydium, and Meteora?**
Not currently. These three cover the majority of Solana CLMM liquidity.
Additional protocol support is the most welcome contribution — see Contributing
below.

**Can I run this on mobile or Termux?**
Yes, intentionally. The skill has no native dependencies beyond standard HTTP
fetch and JSON parsing, which are available in any environment including
Termux on Android.

## License

MIT — see [LICENSE](./LICENSE).

## Contributing

PRs welcome, especially for:
- Additional CLMM protocols
- More precise IL modeling for concentrated ranges
- Historical entry-price tracking from transaction history
- Improved Meteora DLMM bin-to-price approximation
```


