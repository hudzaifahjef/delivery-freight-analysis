/* =====================================================================
   Project  : Delivery Performance & Freight Cost Analysis
   File     : 03_model_dw.sql
   Purpose  : Build the cleaned model: fact_orders with a quality flag,
              fact_order_items, dim_customers and dim_sellers.
   Database : SQL Server, database LogistikPortfolio
   Depends  : 01_staging_check.sql, 02_profiling.sql (schemas stg and dw exist)
   Run order: Third script. Safe to re-run: each table is dropped and rebuilt.
   Notes    : - Rows are flagged, not deleted. Raw data stays intact and every
                exclusion can be audited from quality_flag.
              - Only orders with status 'delivered' enter fact_orders, because
                late or on-time cannot be judged for undelivered orders.
              - CASE order assigns each row to exactly one flag.
              - Currency in Olist is BRL.
   ===================================================================== */

USE LogistikPortfolio;
GO
 
 
/* ---------------------------------------------------------------------
   1. fact_orders: typed timestamps, delivered orders only
   --------------------------------------------------------------------- */
DROP TABLE IF EXISTS dw.fact_orders;
GO

CREATE SCHEMA dw;
GO
SELECT
  order_id,
  customer_id,
  order_status,
  TRY_CONVERT(datetime, order_purchase_timestamp)        AS purchase_ts,
  TRY_CONVERT(datetime, order_approved_at)               AS approved_ts,
  TRY_CONVERT(datetime, order_delivered_carrier_date)    AS carrier_ts,
  TRY_CONVERT(datetime, order_delivered_customer_date)   AS delivered_ts,
  TRY_CONVERT(datetime, order_estimated_delivery_date)   AS estimated_ts
INTO dw.fact_orders
FROM stg.olist_orders_dataset
WHERE order_status = 'delivered';   -- keputusan: analisis keterlambatan hanya untuk pesanan terkirim
GO
-- Result: 96,478 rows

/* ---------------------------------------------------------------------
   1.1. fact_orders: Other Problem Identified from dw.fact_orders
   --------------------------------------------------------------------- */
SELECT
  SUM(CASE WHEN delivered_ts IS NULL THEN 1 ELSE 0 END) AS delivered_tanpa_tgl_terkirim,
  SUM(CASE WHEN delivered_ts < purchase_ts OR carrier_ts < purchase_ts THEN 1 ELSE 0 END) AS delivered_tgl_tidak_logis,
  SUM(CASE WHEN delivered_ts < carrier_ts THEN 1 ELSE 0 END) AS terkirim_sebelum_diserahkan_kurir
FROM dw.fact_orders;
-- Result: Delivererd without Delivery Date 8 | Delivererd but Date is not logic 165 | Delivered date lower then carrier date 23

/* ---------------------------------------------------------------------
   2. Quality flag
   Question : Which delivered orders can be trusted for lead time analysis?
   Note     : ALTER and UPDATE are in separate batches (GO) so the new column
              exists before it is referenced.
   --------------------------------------------------------------------- */

ALTER TABLE dw.fact_orders ADD quality_flag VARCHAR(30);
GO

UPDATE dw.fact_orders
SET quality_flag = CASE
  WHEN delivered_ts IS NULL THEN 'no_delivered_date'
  WHEN delivered_ts < purchase_ts OR carrier_ts < purchase_ts THEN 'illogical_vs_purchase'
  WHEN delivered_ts < carrier_ts THEN 'delivered_before_carrier'
  WHEN carrier_ts IS NULL THEN 'no_carrier_date'
  ELSE 'ok'
END;
GO

-- Flag distribution (this feeds docs/data_quality_log.md)
SELECT 
	quality_flag, 
	COUNT(*) AS n,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS pct
FROM dw.fact_orders
GROUP BY quality_flag
ORDER BY n DESC;
-- Result: ok 96,281 (99.80%) | illogical_vs_purchase 165 | delivered_before_carrier 23
--         | no_delivered_date 8 | no_carrier_date 1
-- Check: 96,281 + 165 + 23 + 8 + 1 = 96,478 (no row lost or counted twice)

/* ---------------------------------------------------------------------
   3. Dimensions: customers and sellers
   --------------------------------------------------------------------- */
DROP TABLE IF EXISTS dw.dim_customers;
GO

SELECT 
	customer_id, 
	customer_unique_id,
    customer_city  AS city,
    customer_state AS state
INTO dw.dim_customers
FROM stg.olist_customers_dataset;
GO

DROP TABLE IF EXISTS dw.dim_sellers;
GO
	
SELECT seller_id,
       seller_city  AS city,
       seller_state AS state
INTO dw.dim_sellers
FROM stg.olist_sellers_dataset;
GO


/* ---------------------------------------------------------------------
   4. fact_order_items: freight and price per item
   Note     : price and freight_value are text in staging, so they are
              converted here. Freight lives at item level, not order level.
   --------------------------------------------------------------------- */
DROP TABLE IF EXISTS dw.fact_order_items;
GO

SELECT 
	order_id,
	order_item_id,
	product_id,
	seller_id,
	TRY_CONVERT(decimal(10,2), price) AS price,
	TRY_CONVERT(decimal(10,2), freight_value) AS freight_value
INTO dw.fact_order_items
FROM stg.olist_order_items_dataset;
GO


-- Check: did any conversion fail and turn into NULL?
SELECT
	COUNT(*) AS total,
	SUM(CASE WHEN price IS NULL OR freight_value IS NULL THEN 1 ELSE 0 END) AS failed_convertion
FROM dw.fact_order_items;
-- Result: (add after running; failed_conversion should be 0)

