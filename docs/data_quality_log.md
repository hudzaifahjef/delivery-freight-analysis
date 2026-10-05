# Data Quality Log

Dataset: Olist Brazilian E-Commerce (public, Kaggle) · Table audited: `orders` · Platform: SQL Server

All counts below come from queries in [`sql/02_profiling.sql`](../sql/02_profiling.sql) and can be re-run.

## Summary

| Stage | Rows | Share |
|---|---|---|
| Raw orders (staging) | 99,441 | 100.00% |
| Orders with status `delivered` | 96,478 | 97.02% of raw |
| **Final analysis dataset (`quality_flag = 'ok'`)** | **96,281** | **96.82% of raw · 99.80% of delivered** |

## Issues found and decisions

| # | Issue | Rows | % of raw | Decision | Rationale |
|---|---|---|---|---|---|
| 1 | Duplicate `order_id` | 0 | 0.00% | No action | Primary key verified unique |
| 2 | Status other than `delivered` (shipped, canceled, unavailable, invoiced, processing, created, approved) | 2,963 | 2.98% | Excluded from delay analysis | Not yet delivered, so on-time vs late cannot be judged |
| 3 | Delivered, but delivery or carrier date earlier than purchase date | 165 | 0.17% | Flagged `illogical_vs_purchase`, excluded | Timeline is impossible |
| 4 | Delivered to customer before handed to carrier | 23 | 0.02% | Flagged `delivered_before_carrier`, excluded | Stage order is reversed, lead time per stage unreliable |
| 5 | Delivered, but delivery date missing | 8 | 0.01% | Flagged `no_delivered_date`, excluded | Lead time cannot be computed |
| 6 | Delivered, but carrier date missing | 1 | 0.00% | Flagged `no_carrier_date`, excluded | Stage split (seller vs transit) cannot be computed |

Check: 96,281 + 165 + 23 + 8 + 1 = 96,478 delivered orders. No row lost or double counted.

## Method

- Staging tables (`stg`) load every column as text. Type conversion happens in the model layer with `TRY_CONVERT`, so bad values become `NULL` instead of failing the load.
- Rows are **flagged, not deleted**. Raw data stays intact, and each exclusion can be audited from `dw.fact_orders.quality_flag`.
- `CASE` order in the flag logic assigns each row to exactly one category, so counts never overlap.

## Definitions used downstream

- **Late order:** `delivered_ts > estimated_ts` (delivered after the date promised to the customer).
- **Seller processing time:** approved to handed to carrier.
- **Transit time:** handed to carrier to received by customer. Olist has no separate last-mile timestamp, so last mile is included here.
