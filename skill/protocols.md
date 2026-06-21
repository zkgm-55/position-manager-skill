# Protocol Reference: Orca Whirlpools, Raydium CLMM, Meteora DLMM

This file covers how to fetch position data from each protocol REST API, with RPC fallback noted but detailed separately in rpc-fallback.md.

## 1. Identifying which protocol a position belongs to

If the user gives a wallet address, query all three APIs filtered by owner; each returns an empty list harmlessly if the wallet has no positions there.

If the user gives a specific position or NFT mint address and the protocol is unknown:
1. Try Orca position-by-mint endpoint first (most common on Solana mainnet).
2. If 404, try Raydium position lookup.
3. If still not found, try Meteora DLMM position lookup.
4. If none resolve, the address may not be a CLMM position at all; say so rather than guessing.

## 2. Orca Whirlpools

Orca exposes a public REST API for indexed pool and position data.

- Base URL: https://api.orca.so
- Positions by wallet: GET /v2/solana/positions?wallet=WALLET_ADDRESS
- Pool detail (for current price or tick): GET /v2/solana/whirlpool/WHIRLPOOL_ADDRESS

Key response fields to extract per position:
- whirlpoolAddress: the pool this position belongs to
- tickLowerIndex, tickUpperIndex: the position range, in ticks
- liquidity: raw liquidity units (needed for IL or value calcs, see analysis.md)
- feeOwedA, feeOwedB: unclaimed fees in each token
- Pool tickCurrentIndex: compare against the position tick bounds to determine in or out-of-range

Converting ticks to human-readable price: price equals 1.0001 raised to the power of tick.

Adjust for token decimals when presenting to the user. If the public API response shape has changed or a field is missing, do not guess; fall back to RPC parsing (rpc-fallback.md) rather than fabricating a number.

## 3. Raydium CLMM

Raydium provides a public API for pool and position data.

- Base URL: https://api-v3.raydium.io
- Pool info: GET /pools/info/ids?ids=POOL_ID
- Positions are typically fetched by querying the user token accounts for position NFTs, then resolving each via the pool program. If a direct positions-by-wallet endpoint is not available, fall back to RPC: enumerate the wallet token accounts, identify CLMM position NFTs by mint pattern, then fetch position state accounts.

Key fields:
- tickLower, tickUpper: range bounds
- liquidity
- Current pool tick or price from the pool info response

Same tick-to-price formula as Orca, since Raydium CLMM also uses Uniswap-v3-style ticks.

## 4. Meteora DLMM

Meteora Dynamic Liquidity Market Maker uses bins, not ticks; structurally similar in purpose (discrete price ranges) but a different math model. Do not reuse the Orca or Raydium tick formula here.

- Base URL: https://dlmm-api.meteora.ag
- Positions by wallet: GET /position/WALLET_ADDRESS (verify the endpoint is live before relying on it; Meteora API surface has changed before; fall back to RPC if it 404s)
- Pool detail: GET /pair/PAIR_ADDRESS

Key fields:
- lowerBinId, upperBinId: the position range in bins
- activeBin: the pool current active bin (compare against the position bin range for in or out-of-range)
- Unclaimed fees are typically reported per-bin; sum across the position bin range

Bin-to-price formula (approximate, depends on the pair configured bin step): price equals (1 plus binStep divided by 10000) raised to the power of binId. binStep is in basis points and is part of the pair config; fetch it from the pool detail response rather than assuming a default.

## 5. General notes

- Rate limits: these are public APIs without guaranteed SLAs. Space out requests when checking multiple positions or protocols, and do not retry aggressively on failure; fall back to RPC instead.
- Staleness: API responses may lag the chain tip by a few seconds. For time-sensitive decisions, mention this caveat rather than presenting numbers as instantaneous.
- Do not fabricate fields: if an API response is missing an expected field, say what is missing rather than inventing a plausible-looking number. This matters most for fee and liquidity values, which directly inform financial decisions.
