CREATE DATABASE LogistikPortfolio;
GO
USE LogistikPortfolio;
GO
CREATE SCHEMA stg;
GO

-- ) Identify row number for each available table
SELECT 'orders' AS tbl, COUNT(*) AS n FROM stg.olist_orders_dataset
  UNION ALL SELECT 'order_items', COUNT(*) FROM stg.olist_order_items_dataset
  UNION ALL SELECT 'sellers', COUNT(*) FROM stg.olist_sellers_dataset
  UNION ALL SELECT 'customers', COUNT(*) FROM stg.olist_customers_dataset
  UNION ALL SELECT 'geolocation_zip_code_prefix', COUNT(*) FROM stg.olist_geolocation_dataset
  UNION ALL SELECT 'order_id', COUNT(*) FROM stg.olist_order_payments_dataset
  UNION ALL SELECT 'review_id', COUNT(*) FROM stg.olist_order_reviews_dataset
  UNION ALL SELECT 'product_id', COUNT(*) FROM stg.olist_products_dataset
  UNION ALL SELECT 'column1', COUNT(*) FROM stg.product_category_name_translation
;
