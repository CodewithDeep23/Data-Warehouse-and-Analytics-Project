/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/


/*
=======================================
Create Dimension: gold.dim_customers
=======================================
*/

CREATE OR REPLACE VIEW gold.dim_customer AS
SELECT
	ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,    -- Surrogate key
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	ci.cst_marital_status AS marital_status,
	cl.cntry AS country,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master for gender info
		 ELSE COALESCE(ca.gen, 'n/a')               -- Fallback to ERP data
	END AS gender,
	ca.bdate AS birthdate,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON 	ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS cl
ON ci.cst_key = cl.cid;


/*
=======================================
Create Dimension: gold.dim_product
=======================================
*/

CREATE OR REPLACE VIEW gold.dim_product AS
SELECT
	ROW_NUMBER() OVER (ORDER BY pi.prd_start_dt, pi.prd_key) AS product_key,   -- Surrogate key
	pi.prd_id AS product_id,
	pi.prd_key AS product_number,
	pi.prd_nm AS product_name,
	pi.cat_id AS category_id,
	pc.cat AS category,
	pc.subcat AS sub_category,
	pc.maintenance,
	pi.prd_cost AS product_cost,
	pi.prd_line AS product_line,
	pi.prd_start_dt AS product_start_date
FROM silver.crm_prd_info AS pi
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
ON pi.cat_id = pc.id
WHERE pi.prd_end_dt IS NULL;     -- Filter out all historical data


/*
=======================================
Create Fact: gold.fact_sales
=======================================
*/

CREATE OR REPLACE VIEW gold.fact_sales AS
SELECT
	sd.sls_ord_num AS order_number,
	dc.customer_key,
	dp.product_key,
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price AS price,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS due_date
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_customer AS dc
ON sd.sls_cust_id = dc.customer_id
LEFT JOIN gold.dim_product AS dp
ON sd.sls_prd_key = dp.product_number;