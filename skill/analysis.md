# Analysis Reference: Range Status, Impermanent Loss, Fee Yield

This file covers the calculations used to evaluate a CLMM position health once raw data has been fetched per protocols.md.

## 1. In-range vs out-of-range

A position earns fees only while the pool current price sits within the position bounds.

- Orca and Raydium (tick-based): in-range if tickLower is less than or equal to tickCurrent, and tickCurrent is less than or equal to tickUpper.
- Meteora (bin-based): in-range if lowerBinId is less than or equal to activeBin, and activeBin is less than or equal to upperBinId.

When out-of-range, identify which side:
- Current price or tick above the upper bound: position has fully converted to the quote-side asset (for example all USDC in a SOL/USDC pool) and is waiting for price to fall back, or for the LP to actively manage it.
- Current price or tick below the lower bound: position has fully converted to the base-side asset (all SOL) and is waiting for price to rise back into range.

This directional detail matters: it tells the user whether staying out-of-range is a bullish or bearish bet on the underlying asset, which should inform whether they rebalance or wait.

## 2. Distance to range edge

Useful for flagging positions that are about to go out of range, not just ones that already have.

distance_to_upper_pct equals (priceUpper minus priceCurrent) divided by priceCurrent, times 100.
distance_to_lower_pct equals (priceCurrent minus priceLower) divided by priceCurrent, times 100.

A reasonable default warning threshold: flag a position as near edge if either distance is under 5 percent, but treat this as a starting heuristic, not a hard rule. Volatile pairs may warrant a wider buffer, stable pairs a tighter one. If the user has a stated risk preference, use that instead of the default.

## 3. Impermanent loss (IL) estimate

IL compares the value of LP assets against simply holding the original deposit amounts unpooled.

Standard two-asset constant-product IL formula (applies reasonably well as an approximation even for concentrated ranges, though concentrated positions experience amplified IL within their range compared to full-range LPs):

price_ratio equals current_price divided by entry_price.
IL_pct equals (2 times the square root of price_ratio, divided by (1 plus price_ratio)) minus 1.

This yields a negative percentage representing value lost to divergence, before accounting for fees earned. Always present IL alongside fees earned, not in isolation; a position can have negative IL but still be net-positive once fees are included.

net_pnl_pct is approximately IL_pct plus fee_yield_pct.

Caveats to surface to the user when giving an IL estimate:
- This formula assumes full-range LP dynamics; concentrated positions amplify both gains and IL relative to a full-range position covering the same price move, roughly proportional to how narrow the range is. Frame the IL number as a directional estimate, not a precise one.
- It does not account for entry or exit slippage or transaction costs.
- If entry_price is not available from the API, which is common since most APIs report current state rather than historical entry, say so explicitly rather than guessing an entry price. Ask the user for it, or skip the IL estimate and report fees and range status only.

## 4. Fee yield

Unclaimed fees are usually returned directly by the API or RPC (see protocols.md field names). To express this as a yield:

fee_yield_pct equals unclaimed_fee_value_usd divided by position_value_usd, times 100.

For an annualized estimate, the user needs to know how long the position has been open; ask if it is not available, rather than assuming a timeframe.

annualized_fee_yield_pct equals fee_yield_pct times (365 divided by days_position_open).

Annualizing a short observation window, for example a position open 2 days, produces a misleadingly large number; flag this explicitly when days_position_open is small, under about 7 days, rather than presenting the annualized figure at face value.

## 5. Worked example

Position: SOL/USDC on Orca, range 142.10 to 168.40 dollars, current price 171.20 dollars, entry price 150.00 dollars, unclaimed fees 4.12 dollars, position value 1000 dollars.

Status: OUT OF RANGE (above upper bound).
distance_to_upper_pct: about negative 1.6 percent, meaning already past it.
price_ratio: 171.20 divided by 150.00, equals about 1.141.
IL_pct: approximately negative 0.31 percent.
fee_yield_pct: 4.12 divided by 1000, equals 0.41 percent.
net_pnl_pct: approximately positive 0.10 percent, roughly breakeven, slightly positive.

Present this as: your position has been out of range and is not earning fees right now. Versus just holding, you are roughly breakeven once fees are factored in, but you are not earning anything further until price moves back into range or you rebalance.
