# position-manager-skill

A Claude Code / agentic-coding skill for managing Solana CLMM (concentrated liquidity) positions across Orca Whirlpools, Raydium CLMM, and Meteora DLMM.

Submitted for the Solana AI Kit community bounty (Superteam Brasil), leveling up the position-manager-skill seed idea to production grade.

## The problem

Concentrated liquidity positions lose money silently. When price moves outside a position range, fee accrual stops completely, but most LPs do not notice until they check manually, by which point they have been earning nothing for days. Nobody in the current Solana agent-skill ecosystem has a cross-protocol position health checker. Every existing tool is single-protocol, and most require a full SDK install that does not fit lean or mobile build environments.

## What this skill does

Given a wallet address (or a specific position), this skill:

1. Finds open LP positions across Orca, Raydium, and Meteora
2. Reports in-range or out-of-range status for each, with which direction price moved
3. Estimates impermanent loss and fee yield, net of each other
4. Flags positions near the edge of their range before they go out-of-range
5. Suggests, never executes, rebalancing options, framed as a tradeoff rather than a directive

This skill is read-only. It never constructs, signs, or sends transactions, and never handles private keys. It is an analysis and decision-support tool, not a trading bot.

## Why this design

- Progressive disclosure: the main SKILL.md is a router. Detailed protocol API specs, math formulas, and rebalancing logic live in separate reference files, loaded only when the task needs them.
- REST API first, RPC fallback: each protocol public REST API is used by default for speed and simplicity. If an API is down, rate-limited, or does not index a position, the skill falls back to direct Solana RPC account parsing (skill/rpc-fallback.md).
- No SDK dependency required: works in constrained environments such as mobile or Termux where installing full protocol SDKs is not practical.
- Honesty over confidence: every reference file explicitly instructs against fabricating numbers when data is missing or an API or RPC call fails.

## Structure

position-manager-skill/
- README.md
- LICENSE
- install.sh
- skill/SKILL.md
- skill/protocols.md
- skill/analysis.md
- skill/rebalancing.md
- skill/rpc-fallback.md
- skill/resources.md
- agents/position-health-checker.md
- commands/check-positions.md

## Install

git clone https://github.com/zkgm-55/position-manager-skill.git
cd position-manager-skill
./install.sh

This copies skill/ into your project .claude/skills/position-manager-skill/ directory. No build step, no dependencies beyond standard fetch or curl plus JSON parsing.

## Usage examples

Once installed, the skill triggers automatically on relevant requests, such as checking LP positions on a wallet, asking if a Whirlpool position is still in range, asking whether to rebalance a Meteora DLMM position, or asking about impermanent loss on Raydium.

## Scope and limitations

- Read-only: does not execute swaps, opens, closes, or rebalances.
- IL estimates are directional approximations, not precise accounting.
- Public protocol APIs are unofficial and rate-limited; pair with a dedicated RPC provider for high-frequency monitoring.

## License

MIT, see LICENSE file.

## Contributing

PRs welcome, especially for additional CLMM protocols, more precise IL modeling for concentrated ranges, and historical entry-price tracking.
