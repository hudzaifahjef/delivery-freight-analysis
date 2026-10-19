/* =====================================================================
   Project  : Delivery Performance & Freight Cost Analysis
   File     : 05_analysis.sql
   Purpose  : Answer the business questions listed in README.md
   Database : SQL Server, database LogistikPortfolio
   Depends  : 03_model_dw.sql (dw.fact_orders, dw.fact_order_items,
              dw.dim_customers, dw.dim_sellers)
              04_kpi_views.sql (dw.vw_order_kpi)
   Run order: top to bottom. Section 3 and section 4 each create a
              temp table first; the queries below them read from it.
              Temp tables disappear when the SSMS window is closed.
   Notes    : - Late order = delivered after the estimated date.
              - Only rows with quality_flag = 'ok' are analysed
                (see docs/data_quality_log.md).
              - "Result" comments record what each query returned
                when last run, so the README numbers can be traced.
   ===================================================================== */
 
USE LogistikPortfolio;
GO


/* ---------------------------------------------------------------------
   1. Overall KPI
   Question : What share of deliveries is late, and which stage is slower?
   --------------------------------------------------------------------- */
SELECT
  COUNT(*)                                              AS total_ok,
  SUM(is_late)                                          AS total_late,
  CAST(100.0 * SUM(is_late) / COUNT(*) AS DECIMAL(5,2)) AS late_pct,
  CAST(AVG(days_seller_processing) AS DECIMAL(5,2))     AS avg_seller_days,
  CAST(AVG(days_transit) AS DECIMAL(5,2))               AS avg_transit_days
FROM dw.vw_order_kpi;
-- Result: 96,281 orders | 7,822 late | 8.12% | seller 2.80 days | transit 9.33 days
	

/* ---------------------------------------------------------------------
   2. Lead time percentiles
   Question : What is the typical wait (P50) and the bad-case wait (P90)?
   Why      : Averages are pulled up by extreme orders; percentiles are not.
   --------------------------------------------------------------------- */
SELECT DISTINCT
  CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_seller_processing) OVER () AS DECIMAL(5,1)) AS seller_p50,
  CAST(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY days_seller_processing) OVER () AS DECIMAL(5,1)) AS seller_p90,
  CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_transit)           OVER () AS DECIMAL(5,1)) AS transit_p50,
  CAST(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY days_transit)           OVER () AS DECIMAL(5,1)) AS transit_p90,
  CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_total)             OVER () AS DECIMAL(5,1)) AS total_p50,
  CAST(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY days_total)             OVER () AS DECIMAL(5,1)) AS total_p90
FROM dw.vw_order_kpi;
-- Result: seller 1.8 / 6.0 | transit 7.1 / 18.9 | total 10.2 / 23.1 (days, P50 / P90)




-- #1 Analysist: Region with the worst late
SELECT *
FROM dw.vw_order_kpi;

SELECT *
FROM dw.dim_customers;

SELECT TOP 10
  c.state,
  COUNT(*) AS orders,
  SUM(k.is_late) AS late_orders,
  CAST(100.0 * SUM(k.is_late) / COUNT(*) AS DECIMAL(5,2)) AS late_pct,
  CAST(AVG(k.days_total) AS DECIMAL(5,1)) AS avg_days_total
FROM dw.vw_order_kpi k
JOIN dw.dim_customers c ON c.customer_id = k.customer_id
GROUP BY c.state
ORDER BY late_pct DESC;


-- #2 Rank for the top worst seller by delivered time
WITH seller_orders AS (
SELECT DISTINCT
	i.seller_id,
	k.order_id,
	k.is_late
FROM dw.vw_order_kpi k
JOIN dw.fact_order_items i ON k.order_id = i.order_id
),

seller_stats AS (
SELECT
	seller_id,
	COUNT(is_late) as total_orders,
	SUM(is_late) as total_late,
	CAST(100.0 * SUM(is_late) / COUNT(is_late) as decimal (5,2)) as late_pct
FROM seller_orders
GROUP BY seller_id
HAVING COUNT(is_late) >= 30
)

SELECT TOP 10
	RANK () OVER (ORDER BY late_pct DESC) AS late_rank,
	ss.seller_id, 
	ds.state,
	ss.total_orders,
	ss.late_pct
FROM seller_stats ss
JOIN dw.dim_sellers ds ON ss.seller_id = ds.seller_id
;


-- #3 Percentile Lead Time
SELECT DISTINCT
  CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_seller_processing) OVER () AS DECIMAL(5,1)) AS seller_p50,
  CAST(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY days_seller_processing) OVER () AS DECIMAL(5,1)) AS seller_p90,
  CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_transit) OVER () AS DECIMAL(5,1)) AS transit_p50,
  CAST(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY days_transit) OVER () AS DECIMAL(5,1)) AS transit_p90,
  CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_total) OVER () AS DECIMAL(5,1)) AS total_p50,
  CAST(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY days_total) OVER () AS DECIMAL(5,1)) AS total_p90
FROM dw.vw_order_kpi;
