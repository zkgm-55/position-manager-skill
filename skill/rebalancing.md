# Rebalancing Reference: Decision Framework

This skill never executes a rebalance. This file governs how to reason about whether to suggest one and how to phrase the suggestion. The user, or their own tooling, executes any action.

## When to surface a rebalancing suggestion

Only raise it when one of these is true:
1. The position is currently out-of-range and earning zero fees.
2. The position is within the near edge threshold from analysis.md (default 5 percent, adjustable to user stated risk tolerance) and trending toward going out-of-range based on recent price movement, if that data is available.

Do not suggest rebalancing a healthy in-range position just to seem proactive; that is noise, not signal. If everything looks fine, say so plainly and stop.

## Decision factors to weigh, and state explicitly

A rebalance suggestion should never be a bare yes or no. Walk through the tradeoff:

1. Directional view: rebalancing out-of-range positions effectively means converting the now single-asset position back into a balanced pair at the current price, which locks in the price move that pushed it out of range. If the user expects price to revert back into the old range, waiting may be better than rebalancing. If they expect the trend to continue, rebalancing closer to the new price re-enables fee accrual.
2. Cost of rebalancing: closing and reopening a CLMM position costs transaction fees and, if it involves the position NFT, may have minor slippage on the swap needed to rebalance the token ratio. For small positions, this cost can outweigh the resumed fee yield over a short window.
3. Range width tradeoff: if a position keeps drifting out of range repeatedly, a wider range trades lower fee APR (less concentrated) for less frequent rebalancing. Worth mentioning if the user describes this as a recurring problem.
4. Cost of inaction: a position sitting out-of-range for a long period earns nothing; point this out as a cost too, not just rebalancing as a cost.

## Phrasing the suggestion

Present it as a framed decision, not a directive. Example pattern:

Your SOL/USDC position has been out of range for some time. You have two reasonable paths: rebalance now to resume fee accrual at the current price, or wait if you think price will revert into your old range. Rebalancing costs roughly some amount in fees. Given the context you have shared about your outlook, here is how I would think about it.

Avoid absolute language like you should rebalance now unless the user has explicitly asked for a single recommendation rather than a tradeoff discussion.

## What this skill does NOT do

- Does not construct or submit a close-position or reopen-position transaction.
- Does not recommend a specific new range without the user confirming their risk tolerance and price outlook first; a default tighten the range by some percent suggestion without that context is just guessing.
- Does not give directional price predictions as fact. Frame any reference to if price reverts or if the trend continues as the user own stated view, not the skill prediction.
