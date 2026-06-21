---
name: position-manager-skill
description: Manage and monitor concentrated liquidity (CLMM) positions on Solana across Orca Whirlpools, Raydium CLMM, and Meteora DLMM. Use this skill whenever the user asks about LP positions, impermanent loss, in-range or out-of-range status, rebalancing, fee yield, or concentrated liquidity strategy on Solana. Trigger on mentions of my LP position, Whirlpool, Raydium pool, Meteora DLMM, out of range, rebalance my liquidity, impermanent loss, or any wallet address paired with a request to check liquidity positions. Also trigger for portfolio-wide LP health checks such as how are my positions doing even without naming a specific protocol.
compatibility: Requires network access (REST API calls to Orca, Raydium, and Meteora endpoints, with Solana RPC fallback). No build step. Works in any environment with curl or fetch and basic JSON parsing (Node.js, Python, or shell).
---

# Position Manager Skill

A Solana CLMM (Concentrated Liquidity Market Maker) position management skill. It finds a wallet open LP positions across Orca Whirlpools, Raydium CLMM, and Meteora DLMM, evaluates their health (in-range vs out-of-range, impermanent loss, accrued fees), and suggests rebalancing actions, all read-only, no transactions are signed or sent.

## Why this skill exists

CLMM LPs lose money silently when a position drifts out of range: fees stop accruing but the position is still exposed to both-sided price risk. Nobody in the Solana agent-skill ecosystem has a cross-protocol position health checker. This skill fills that gap.

## Scope and safety boundaries

This skill is read-only by design:
- It only fetches and analyzes on-chain or API data.
- It never constructs, signs, or sends transactions.
- It never asks for or handles private keys or seed phrases.
- Rebalancing suggestions are informational only; the user executes them manually or via the protocol own UI or SDK.

If a user asks this skill to actually execute a rebalance or withdrawal, stop and clarify that this skill only analyzes and recommends; it does not move funds.

## Routing

Read the relevant reference file(s) based on what the user needs:

- Find or list a wallet open positions across protocols: read protocols.md
- Determine in-range or out-of-range status, IL estimate, fee yield: read analysis.md
- Decide whether or how to suggest a rebalance: read rebalancing.md
- API is down, rate-limited, or position not found via API: read rpc-fallback.md

Load only what is needed for the current task; do not read all files for a simple is my position in range check.

## Core workflow

1. Identify the wallet and protocol(s). If the user gives a wallet address, scan all three protocols unless they specify one. If they paste a position or NFT mint address instead, identify which protocol it belongs to first (see protocols.md).
2. Fetch position data via the protocol REST API first (faster, pre-parsed). Fall back to direct RPC account parsing per rpc-fallback.md if the API fails or the position is not indexed.
3. Compute health metrics: current price vs position range, distance to range edges, unclaimed fees, and a rough impermanent loss estimate versus holding the underlying assets. See analysis.md for formulas.
4. Summarize clearly: for each position, report protocol, pair, range, current price, in or out-of-range status, and unclaimed fees. Lead with the in-range verdict.
5. If out-of-range or near the edge, apply the decision logic in rebalancing.md to suggest, not execute, a course of action, and explain the tradeoff in plain terms.

## Output format

Default to a compact per-position summary, for example:

Protocol Orca, pair SOL/USDC, Range 142.10 to 168.40, Current 171.20.
Status: OUT OF RANGE (above), 0 percent fee accrual.
Unclaimed fees: about 4.12 dollars.
Suggestion: price has moved 1.7 percent above range; consider rebalancing if you expect continued upside, or wait if you expect reversion.

For multiple positions, summarize each this way, then give a one-line portfolio-level takeaway.

## Key terminology

- In-range: current pool price falls between the position lower and upper bounds; fees accrue.
- Out-of-range: current price has moved outside the bounds; the position now holds one asset and earns zero fees until price returns or the position is rebalanced.
- Tick: the discrete price unit CLMMs use to define ranges (Orca and Raydium use ticks; Meteora DLMM uses bins, a similar but distinct concept, see protocols.md).
- Impermanent loss (IL): the value difference between holding LP assets versus simply holding them unpooled, caused by price divergence.

## Resources

- protocols.md: API endpoints, auth, and response shapes for Orca, Raydium, Meteora; how to identify protocol from a position address
- analysis.md: range, IL, and fee-yield calculation formulas and worked examples
- rebalancing.md: decision framework for when a rebalance suggestion is warranted, and what to tell the user
- rpc-fallback.md: direct Solana RPC account parsing when REST APIs are unavailable
- resources.md: links to official protocol docs and SDKs for deeper reference
