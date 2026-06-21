# RPC Fallback Reference

Use this when a protocol REST API is down, rate-limited, returns an unexpected shape, or simply does not index a given position (common for very new positions, or for Raydium which lacks a direct positions-by-wallet endpoint in all cases, see protocols.md).

## General approach

1. Use a public or user-provided Solana RPC endpoint. If the user has not specified one, a public mainnet-beta RPC endpoint can be used for read-only queries, but mention that public endpoints are rate-limited and a dedicated RPC provider such as Helius, Triton, or QuickNode will be more reliable for repeated checks.
2. Enumerate the wallet token accounts via getTokenAccountsByOwner to find position NFTs (balance of 1, 0 decimals).
3. Match the NFT mint against each protocol known position-account derivation to identify which protocol, if any, it belongs to, and to find the corresponding position state account.
4. Fetch the position state account via getAccountInfo and decode it according to the protocol account layout.

## Decoding without an SDK

Manually decoding raw account bytes is error-prone and protocol-specific layouts change over time. Prefer this order of preference:
1. If the protocol SDK is available in the working environment, use it to decode the account rather than hand-rolling a byte parser.
2. If no SDK is available, for example in a constrained mobile or Termux environment with no room for a heavy SDK install, decode only the specific fields needed (tick bounds, liquidity, fee-owed) using the protocol published account layout or IDL, and clearly comment which byte offsets correspond to which field so it is auditable and fixable if the layout changes.
3. If neither is feasible, say so directly rather than returning a guessed value; a wrong number presented confidently is worse than admitting the position could not be read.

## When RPC fallback still does not resolve

If a position cannot be found or decoded via either API or RPC, tell the user plainly what was tried, what is missing or did not match, and suggest verifying the position or wallet address, or checking directly via the protocol own app as a sanity check.

Do not fabricate plausible-looking position data under any circumstance; this skill informs financial decisions, and a wrong number is worse than no number.
