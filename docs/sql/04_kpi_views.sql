-- KPI
-- On-time rate and leas time per tahap
-- Membuat tabel view untuk menentukan rasio 
CREATE VIEW dw.vw_order_kpi AS
SELECT
  order_id, customer_id, purchase_ts, delivered_ts, estimated_ts,
  CAST(DATEDIFF(HOUR, purchase_ts, approved_ts)  AS DECIMAL(10,2)) / 24 AS days_approval,
  CAST(DATEDIFF(HOUR, approved_ts, carrier_ts)   AS DECIMAL(10,2)) / 24 AS days_seller_processing,
  CAST(DATEDIFF(HOUR, carrier_ts, delivered_ts)  AS DECIMAL(10,2)) / 24 AS days_transit,
  CAST(DATEDIFF(HOUR, purchase_ts, delivered_ts) AS DECIMAL(10,2)) / 24 AS days_total,
  CASE WHEN delivered_ts > estimated_ts THEN 1 ELSE 0 END AS is_late
FROM dw.fact_orders
WHERE quality_flag = 'ok';
GO

SELECT COUNT(*) AS total_ok,
       SUM(is_late) AS total_late,
       CAST(100.0 * SUM(is_late) / COUNT(*) AS DECIMAL(5,2)) AS late_pct,
       CAST(AVG(days_seller_processing) AS DECIMAL(5,2)) AS avg_seller_days,
       CAST(AVG(days_transit) AS DECIMAL(5,2)) AS avg_transit_days
FROM dw.vw_order_kpi;
