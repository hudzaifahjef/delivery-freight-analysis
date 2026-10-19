/* =====================================================================
   Project  : Delivery Performance & Freight Cost Analysis
   File     : 02_profiling.sql
   Purpose  : Profile the raw orders table: size, status mix, duplicates,
              missing dates and illogical dates. Read-only.
   Database : SQL Server, database LogistikPortfolio
   Depends  : 01_staging_check.sql (staging tables loaded in schema stg)
   Run order: Second script. Does not create or change any table.
   Notes    : - Staging columns are text, so date checks use TRY_CONVERT.
              - Findings and decisions are written up in
                docs/data_quality_log.md.
              - The cleaned model is built in 03_model_dw.sql.
   ===================================================================== */

USE LogistikPortfolio;
GO
 
 
/* ---------------------------------------------------------------------
   1. Size and status mix
   Question : How many orders are there, and how many are actually delivered?
   --------------------------------------------------------------------- */
SELECT 
  COUNT(*) AS total_orders 
  FROM stg.olist_orders_dataset;
-- Result: 99,441

SELECT 
  order_status, 
  COUNT(*) AS n
FROM stg.olist_orders_dataset
GROUP BY order_status
ORDER BY n DESC;
-- Result: delivered 96,478 | shipped 1,107 | canceled 625 | unavailable 609 
-- | invoiced 314 | processing 301 | created 5 | approved 2


/* ---------------------------------------------------------------------
   2. Duplicate order_id
   Question : Is order_id a reliable unique key?
   --------------------------------------------------------------------- */
SELECT 
  order_id, 
  COUNT(*) AS C
FROM stg.olist_orders_dataset
GROUP BY order_id 
HAVING COUNT(*) > 1;
-- Result: 0 rows (no duplicates)


/* ---------------------------------------------------------------------
   3. Missing dates
   Question : How many orders lack each key timestamp?
   Note     : Empty strings count as missing because staging columns are text.
   --------------------------------------------------------------------- */
SELECT
  SUM(CASE WHEN order_approved_at IS NULL OR order_approved_at = '' THEN 1 ELSE 0 END) AS null_approved,
  SUM(CASE WHEN order_delivered_carrier_date IS NULL OR order_delivered_carrier_date = '' THEN 1 ELSE 0 END) AS null_carrier,
  SUM(CASE WHEN order_delivered_customer_date IS NULL OR order_delivered_customer_date = '' THEN 1 ELSE 0 END) AS null_delivered
FROM stg.olist_orders_dataset;
-- Result: approved 160 | carrier 1,783 | delivered 2,965
-- Most of these belong to orders that are not delivered (see section 1).
-- Only 8 delivered orders lack a delivery date (see 03_model_dw.sql).


/* ---------------------------------------------------------------------
   4. Illogical dates
   Question : How many orders have a delivery or carrier date earlier than
              the purchase date?
   --------------------------------------------------------------------- */
SELECT 
  COUNT(*) AS tanggal_tidak_logis
FROM stg.olist_orders_dataset
WHERE TRY_CONVERT(datetime, order_delivered_customer_date) < TRY_CONVERT(datetime, order_purchase_timestamp)
   OR TRY_CONVERT(datetime, order_delivered_carrier_date) < TRY_CONVERT(datetime, order_purchase_timestamp);
-- Result: 166 across all statuses (165 among delivered orders, see 03_model_dw.sql)
