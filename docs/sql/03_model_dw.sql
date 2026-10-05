-- Membuat table bersih dengan tipe data yang benar
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


-- Masalah yang tersisa di dalam pesanan 'delivered'
SELECT
  SUM(CASE WHEN delivered_ts IS NULL THEN 1 ELSE 0 END) AS delivered_tanpa_tgl_terkirim,
  SUM(CASE WHEN delivered_ts < purchase_ts OR carrier_ts < purchase_ts THEN 1 ELSE 0 END) AS delivered_tgl_tidak_logis,
  SUM(CASE WHEN delivered_ts < carrier_ts THEN 1 ELSE 0 END) AS terkirim_sebelum_diserahkan_kurir
FROM dw.fact_orders;


-- Membuat quality flag pada setiap baris untuk menandai isu dalam data
-- Menambahkann kolom baru untuk mengisi quality flag
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

-- Summarizing quality flag
SELECT quality_flag, COUNT(*) AS n,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS pct
FROM dw.fact_orders
GROUP BY quality_flag
ORDER BY n DESC;
