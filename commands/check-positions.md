# /check-positions

Quick workflow command: given a wallet address, run a full CLMM position health check across Orca, Raydium, and Meteora.

## Usage

/check-positions WALLET_ADDRESS

Optional flags, interpreted naturally if the user phrases them in prose rather than literal flags:
- protocol filter, for example just check Orca, scopes the check to one protocol instead of all three
- entry price hint, for example I opened this at 150 dollars, enables a real IL estimate instead of skipping it

## What this command does

1. Validates the wallet address looks like a plausible Solana address (base58, correct length) before making any network calls; fail fast on an obviously malformed input rather than burning API calls.
2. Invokes the position-health-checker agent workflow (see agents/position-health-checker.md) for the full portfolio sweep, or the single-position path in SKILL.md if scoped to one protocol or position.
3. Returns the formatted summary as specified in SKILL.md Output Format section.

## Example

User runs /check-positions on a wallet address. Agent returns a portfolio health check with 2 positions found: one out of range on Orca SOL/USDC, drifted 1.6 percent above range, with about 4.12 dollars in unclaimed fees, and a note that rebalancing now would resume fee accrual at the current price but locks in the move, worth considering only if the user does not expect price to revert. The second position, Meteora JTO/SOL, is healthy and within range with a 0.3 percent fee yield so far. Summary: 1 of 2 positions earning fees, offering to help think through whether to rebalance the Orca position.
