# Delivery Performance & Freight Cost Analysis (SQL + Power BI)

**Goal:** find where delays and shipping costs leak, and which routes or vendors are worth fixing first.

## Dataset

[Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (public, from Kaggle). License: see the dataset page on Kaggle.
Raw CSV files are not included in this repo. Download them from the link above.

## Key findings

> Numbers marked TODO are filled in only after the analysis query has been run.

- **8.12%** of delivered orders (7,822 of 96,281) arrived after the promised date.
- Average **transit time is 9.33 days** versus **2.80 days** of seller processing, so transit takes about 3.3x longer.
- Region with the highest late rate: **AL (23.93%)**, about 3x the 8.12% average. Largest absolute impact: **RJ**, with 1,664 late orders (roughly 21% of all late orders).
- Seller performance (minimum 100 orders per seller): delays are spread across many sellers, not concentrated in a few. The 10 sellers with the most late orders (all in SP) account for roughly 15% of late orders, in line with their volume share.
- One high-volume seller (972 orders) is a clear outlier on both measures: 98 late orders and 11.4 days of seller processing versus 2.80 overall. It stays in the results at minimum thresholds of 30 and 100.
- Even if the 10 slowest-processing sellers matched the overall late rate, only about 1% of late orders would be avoided (illustrative estimate), so route and carrier performance is the larger lever.
- Freight cost finding: **TODO**
- Lead time (purchase to delivery): P50 **10.2 days**, P90 **23.1 days**. Transit is the main driver: P50 7.1 days, P90 18.9 days, versus 1.8 and 6.0 days for seller processing.

## Business questions

| Question | Where answered |
|---|---|
| What share of deliveries is late, and which region is worst? | `sql/05_analysis.sql` |
| Which sellers create the most late orders? | `sql/05_analysis.sql` |
| Which sellers are slowest at their own processing step? | `sql/05_analysis.sql` |
| What is freight cost per order, per region, per category? | `sql/05_analysis.sql` (TODO) |
| Which stage is slowest (seller processing vs transit)? | `sql/04_kpi_views.sql` |
| What is the monthly volume trend and 3-month forecast? | `excel/` (TODO) |

## Approach

1. **Cleansing:** type validation, duplicates, nulls, illogical timestamps. Rows are flagged, not deleted. See [`docs/data_quality_log.md`](docs/data_quality_log.md).
2. **Data model:** fact and dimension tables (`fact_orders`, `fact_order_items`, `dim_customers`, `dim_sellers`).
3. **Analysis:** CTEs and window functions (seller ranking, percentiles of lead time).
4. **KPI views:** on-time rate, lead time per stage, freight cost per order.

## How metrics are defined

- **Late order:** delivered after the estimated delivery date promised to the customer. It depends on how realistic that promise was.
- **Seller processing time:** approved to handed to carrier. This is the part sellers control. It is used to judge sellers fairly, separate from carrier transit.
- **Transit time:** handed to carrier to received by customer. Olist has no separate last-mile timestamp, so last mile is included here.
- **Seller analysis:** orders are counted once per seller and order (an order with several items from the same seller is not counted several times). Sellers need a minimum number of orders (100) so that a few unlucky orders do not create a misleading ranking. Results were also checked at 30.
- **Percentiles:** P50 is the typical customer experience, P90 is the experience of the 1 in 10 customers who wait longest.

## What this means

- Delays are driven more by **where orders go and how they travel** than by individual sellers. The 10 worst states by late rate account for roughly 39% of late orders, while the 10 sellers with the most late orders account for roughly 15%.
- **AL** has the worst late rate (23.93%), but **RJ** has the largest absolute impact (1,664 late orders), so RJ is the first place to look for savings.
- Seller fixes are still worthwhile, starting with the one high-volume outlier, but they are a smaller lever than route and carrier performance.

## Data quality in one line

99,441 raw orders, 96,478 delivered, **96,281 clean rows used for analysis (99.80% of delivered)**.

## How to run

Tool: SQL Server (SSMS).

1. Create database `LogistikPortfolio` and schemas `stg` and `dw`.
2. Import the Olist CSV files into schema `stg` with all columns as text.
3. Run the scripts in `sql/` in numeric order (01 to 05).

## Repo structure

```
sql/        SQL scripts, run in order
docs/       data quality log
dashboard/  Power BI screenshots and file (TODO)
excel/      volume forecast (TODO)
```

## Tools

SQL Server · Power BI · Excel
