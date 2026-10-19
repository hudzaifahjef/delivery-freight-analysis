/* =====================================================================
   Project  : Delivery Performance & Freight Cost Analysis
   File     : 04_kpi_views.sql
   Purpose  : Define the KPI view used by all analysis queries: lead time per
              stage and a late flag, one row per clean delivered order.
   Database : SQL Server, database LogistikPortfolio
   Depends  : 03_model_dw.sql (dw.fact_orders with quality_flag)
   Run order: Fourth script. The view can be re-created safely.
   Notes    : - Only rows with quality_flag = 'ok' are included.
              - Late order = delivered after the estimated date promised to
                the customer, so it depends on how realistic that promise was.
              - Stages: approval (purchase to approved), seller processing
                (approved to handed to carrier), transit (handed to carrier to
                received). Olist has no separate last-mile timestamp, so last
                mile is part of transit.
              - Durations are in days (hours divided by 24).
   ===================================================================== */

USE LogistikPortfolio;
GO
 
 
/* ---------------------------------------------------------------------
   1. View: dw.vw_order_kpi
   --------------------------------------------------------------------- */
CREATE VIEW dw.vw_order_kpi AS
SELECT
  order_id, 
  customer_id, 
  purchase_ts, 
  delivered_ts, 
  estimated_ts,
  CAST(DATEDIFF(HOUR, purchase_ts, approved_ts)  AS DECIMAL(10,2)) / 24 AS days_approval,
  CAST(DATEDIFF(HOUR, approved_ts, carrier_ts)   AS DECIMAL(10,2)) / 24 AS days_seller_processing,
  CAST(DATEDIFF(HOUR, carrier_ts, delivered_ts)  AS DECIMAL(10,2)) / 24 AS days_transit,
  CAST(DATEDIFF(HOUR, purchase_ts, delivered_ts) AS DECIMAL(10,2)) / 24 AS days_total,
  CASE WHEN delivered_ts > estimated_ts THEN 1 ELSE 0 END AS is_late
FROM dw.fact_orders
WHERE quality_flag = 'ok';
GO

  
/* ---------------------------------------------------------------------
   2. Sanity check on the view
   Question : What is the overall late rate and the average time per stage?
   --------------------------------------------------------------------- */
SELECT 
  COUNT(*) AS total_ok,
  SUM(is_late) AS total_late,
  CAST(100.0 * SUM(is_late) / COUNT(*) AS DECIMAL(5,2)) AS late_pct,
  CAST(AVG(days_seller_processing) AS DECIMAL(5,2)) AS avg_seller_days,
  CAST(AVG(days_transit) AS DECIMAL(5,2)) AS avg_transit_days
FROM dw.vw_order_kpi;
-- Result: 96,281 orders | 7,822 late | 8.12% | seller 2.80 days | transit 9.33 days
