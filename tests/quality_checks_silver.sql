/*
===============================================================================
DATA QUALITY CHECKS – SILVER LAYER
===============================================================================
Purpose:
    This script validates the integrity and quality of data within the Silver layer.
    It helps ensure data is clean, consistent, and ready for downstream processing.

Key Checks Performed:
    - Detection of NULL or duplicate primary keys.
    - Identification of unwanted spaces in text fields.
    - Standardization and normalization of categorical data.
    - Validation of date fields for correctness and logical ordering.
    - Consistency checks between related numerical fields (e.g., sales = quantity × price).

Usage Instructions:
    - Execute this script after loading data into the Silver layer.
    - Review and address any anomalies before progressing to the Gold layer or analytics.
===============================================================================
*/


/*
==========================================
VALIDATION: crm_cust_info
==========================================
*/

-- Identify NULLs or duplicate customer IDs (Primary Key)
SELECT cst_id, COUNT(*) 
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Detect leading/trailing spaces in customer first names
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

-- Data Standardization & Consistency (cst_gndr and cst_marital_status)
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;


/*
==========================================
VALIDATION: crm_prd_info
==========================================
*/

-- Identify NULLs or duplicate in product IDs
SELECT prd_id, COUNT(*) 
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Detect unwanted spaces in product names
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Identify NULLs or negative values in product cost
SELECT prd_cost 
FROM silver.crm_prd_info 
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- List distinct product lines for normalization
SELECT DISTINCT prd_line
FROM silver.crm_prd_info;

-- Find records with invalid product date ranges (start_date > end_date)
SELECT * 
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


/*
==========================================
VALIDATION: crm_sales_details
==========================================
*/

-- Check for invalid due dates (format or out-of-range)
SELECT NULLIF(sls_due_dt, 0) AS ord_dt
FROM silver.crm_sales_details
WHERE sls_due_dt <= 0 
OR LENGTH(sls_due_dt::TEXT) != 8
OR sls_due_dt > 20500101
OR sls_due_dt < 19000101;

-- Validate date consistency: (Order Date > Shipping/Due Dates)
SELECT * 
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Validate sales data using business rules
/*
Business Rules:
- sls_sales = sls_quantity * sls_price
- Negative, zero, or NULL values are not allowed
*/
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- Note: Data issues exist in sales and price fields
-- Fix Option 1: Clean data at the source system level
-- Fix Option 2: Handle errors in the data warehouse logic


/*
==========================================
VALIDATION: erp_cust_az12
==========================================
*/

-- Detect unrealistic birthdate values
SELECT bdate 
FROM silver.erp_cust_az12
WHERE bdate < '1925-01-01' OR bdate > CURRENT_DATE;

-- Data Standardization & Consistency
SELECT DISTINCT gen 
FROM silver.erp_cust_az12;


/*
==========================================
VALIDATION: erp_loc_a101
==========================================
*/

-- Data Standardization & Consistency
SELECT DISTINCT cntry
FROM silver.erp_loc_a101 ORDER BY cntry;


/*
==========================================
VALIDATION: erp_px_cat_g1v2
==========================================
*/

-- Identify unwanted spaces in category fields
SELECT * 
FROM silver.erp_px_cat_g1v2 
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance);

-- Data Standardization & Consistency
SELECT DISTINCT maintenance 
FROM silver.erp_px_cat_g1v2;