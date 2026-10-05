-- hase 2: Profiling dan cleansing

-- a) Duplikat order_id
SELECT order_id, COUNT(*) c
FROM stg.olist_orders_dataset
GROUP BY order_id HAVING COUNT(*) > 1;

-- b) Null per kolom tanggal penting
SELECT
  SUM(CASE WHEN order_approved_at IS NULL OR order_approved_at = '' THEN 1 ELSE 0 END) AS null_approved,
  SUM(CASE WHEN order_delivered_carrier_date IS NULL OR order_delivered_carrier_date = '' THEN 1 ELSE 0 END) AS null_carrier,
  SUM(CASE WHEN order_delivered_customer_date IS NULL OR order_delivered_customer_date = '' THEN 1 ELSE 0 END) AS null_delivered
FROM stg.olist_orders_dataset;

-- c) Tanggal tidak logis (urutan terbalik)
SELECT COUNT(*) AS tanggal_tidak_logis
FROM stg.olist_orders_dataset
WHERE TRY_CONVERT(datetime, order_delivered_customer_date) < TRY_CONVERT(datetime, order_purchase_timestamp)
   OR TRY_CONVERT(datetime, order_delivered_carrier_date) < TRY_CONVERT(datetime, order_purchase_timestamp);

-- Selanjutnya, membuat tabel bersih dengan data yang benar
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


-- Additional phase: Breakdown nilai kosong pada kolom Tanggal Terkirim
-- 1) Total baris (untuk menghitung persentase)
SELECT COUNT(*) AS total_orders FROM stg.olist_orders_dataset;

-- 2) Sebaran status pesanan
SELECT order_status, COUNT(*) AS n
FROM stg.olist_orders_dataset
GROUP BY order_status
ORDER BY n DESC;

-- 3) Masalah yang tersisa di dalam pesanan 'delivered'
SELECT
  SUM(CASE WHEN delivered_ts IS NULL THEN 1 ELSE 0 END) AS delivered_tanpa_tgl_terkirim,
  SUM(CASE WHEN delivered_ts < purchase_ts OR carrier_ts < purchase_ts THEN 1 ELSE 0 END) AS delivered_tgl_tidak_logis,
  SUM(CASE WHEN delivered_ts < carrier_ts THEN 1 ELSE 0 END) AS terkirim_sebelum_diserahkan_kurir
FROM dw.fact_orders;
