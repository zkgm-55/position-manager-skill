# Position Health Checker Agent

A specialized agent invocation for portfolio-wide CLMM position health checks. Use this when a user wants a full sweep across all three protocols rather than a single-position lookup.

## When to invoke

Invoke this agent pattern when the user asks something portfolio-scoped, for example how are all my LP positions doing, check my wallet for any out-of-range positions, or give me a health summary across Orca, Raydium, and Meteora.

For a single, already-identified position, just follow SKILL.md core workflow directly; spinning up the full agent pattern is unnecessary overhead for a one-position check.

## Agent workflow

1. Resolve the wallet. If not provided, ask for it; do not guess or reuse an address from earlier unrelated context.
2. Query all three protocols in parallel where the environment supports concurrent calls, using protocols.md endpoints. If parallel calls are not available, query sequentially in this order: Orca, Raydium, Meteora.
3. For each position found, run the analysis workflow from analysis.md: range status, distance to edge, fee yield, and IL estimate if entry price is known or supplied.
4. Triage: sort the summary so out-of-range and near-edge positions appear first, since these need attention. Healthy in-range positions can be listed briefly at the end.
5. Portfolio-level takeaway: one or two sentences summarizing overall health, for example 3 of 5 positions are earning fees, 2 are out of range and idle. Keep this factual, not padded with generic encouragement.
6. Only then, apply rebalancing.md decision framework to any position that qualifies for a suggestion (out-of-range or near-edge). Do not suggest rebalancing for healthy positions.

## Output shape for portfolio checks

A portfolio health check summary should list out-of-range positions first with a warning marker, then near-edge positions, then healthy positions, followed by a one-line overall summary. For example: warning, out of range, Raydium BONK/USDC, drifted 4.2 percent below range, idle 6 days, consider rebalancing if you do not expect a bounce. Then: near edge, Orca SOL/USDC, 3.1 percent from upper bound, still earning fees but worth watching. Then: healthy, Meteora JTO/SOL, well within range, about 0.6 percent fee yield so far. Summary: 2 of 3 positions earning fees, the Raydium position has been idle for 6 days, that is the one worth a decision soon.

## Things to avoid

- Do not run this full agent workflow for a casual single-question check; match effort to the actual ask.
- Do not present IL or annualized fee yield numbers without the caveats specified in analysis.md, such as entry price availability and short observation windows.
- Do not recommend a specific protocol as better based on this data alone; fee yield differences may reflect range width choices, pool depth, or time held, not inherent protocol quality.
