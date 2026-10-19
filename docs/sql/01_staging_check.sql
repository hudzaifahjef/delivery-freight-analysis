/* =====================================================================
   Project  : Delivery Performance & Freight Cost Analysis
   File     : 01_staging_check.sql
   Purpose  : Create the database and schemas, then confirm that the Olist
              CSV files were imported completely into the staging schema.
   Database : SQL Server (SSMS)
   Depends  : Olist CSV files imported into schema stg (SSMS: Tasks >
              Import Flat File), every column imported as text.
   Run order: First script of the project. Run section 1, import the CSV
              files, then run section 2.
   Notes    : Staging tables keep every column as text on purpose. Type
              conversion happens in 03_model_dw.sql with TRY_CONVERT, so bad
              values become NULL instead of breaking the import.
   ===================================================================== */


/* ---------------------------------------------------------------------
   1. Database and schemas
   stg = raw staging tables, dw = cleaned model tables and views
   --------------------------------------------------------------------- */
IF DB_ID('LogistikPortfolio') IS NULL
  CREATE DATABASE LogistikPortfolio;
GO
  
USE LogistikPortfolio;
GO
  
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'stg') EXEC('CREATE SCHEMA stg');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'dw')  EXEC('CREATE SCHEMA dw');
GO


/* ---------------------------------------------------------------------
   2. Row counts per staging table
   Question : Did every file load completely?
   Why      : These counts are the "[X] rows" used in the CV bullet and the
              README. Compare them with the row counts of the source CSV files.
   --------------------------------------------------------------------- */
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
-- Result: orders 99,441 | order_items, sellers, customers: (add after running)
-- Add the other Olist tables (payments, reviews, products, geolocation) here if you import them.
