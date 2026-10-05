# Delivery Performance & Freight Cost Analysis (SQL + Power BI)

**Goal:** find where delays and shipping costs leak, and which routes or vendors are worth fixing first.

## Dataset

[Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (public, from Kaggle). License: see the dataset page on Kaggle.
Raw CSV files are not included in this repo. Download them from the link above.

## Key findings

> Numbers marked TODO are filled in only after the analysis query has been run.

- **8.12%** of delivered orders (7,822 of 96,281) arrived after the promised date.
- Average **transit time is 9.33 days** versus **2.80 days** of seller processing, so transit takes about 3.3x longer.
- Region with the highest late rate: **TODO**
- Worst seller by on-time rate (minimum 30 orders): **TODO**
- Freight cost finding: **TODO**
- Lead time P50 / P90: **TODO**

## Business questions

| Question | Where answered |
|---|---|
| What share of deliveries is late, and which region is worst? | `sql/05_analysis.sql` |
| Which sellers have the worst on-time rate? | `sql/05_analysis.sql` |
| What is freight cost per order, per region, per category? | `sql/05_analysis.sql` (TODO) |
| Which stage is slowest (seller processing vs transit)? | `sql/04_kpi_views.sql` |
| What is the monthly volume trend and 3-month forecast? | `excel/` (TODO) |

## Approach

1. **Cleansing:** type validation, duplicates, nulls, illogical timestamps. Rows are flagged, not deleted. See [`docs/data_quality_log.md`](docs/data_quality_log.md).
2. **Data model:** fact and dimension tables (`fact_orders`, `fact_order_items`, `dim_customers`, `dim_sellers`).
3. **Analysis:** CTEs and window functions (seller ranking, percentiles of lead time).
4. **KPI views:** on-time rate, lead time per stage, freight cost per order.

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
