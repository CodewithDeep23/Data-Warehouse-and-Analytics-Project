/*
======================================================
STORED PROCEDURE: LOAD SILVER LAYER (BRONZE -> SILVER)
======================================================
Scripts Purpose:
	This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
Performed Actions:
	- Set datestyle
	- Truncate the tables before loading
	- Insert transformed and cleaned data from bronze into Silver talbes.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
	CALL silver.load_silver();
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
BEGIN
	DECLARE
		start_time TIMESTAMP;
		end_time TIMESTAMP;
		batch_start_time TIMESTAMP;
		batch_end_time TIMESTAMP;
	BEGIN
		batch_start_time := clock_timestamp();
		RAISE NOTICE '====================';
		RAISE NOTICE 'LOADING SILVER LAYER';
		RAISE NOTICE '====================';
		RAISE NOTICE '--------------------';
		RAISE NOTICE 'LOADING CRM TABLES';
		RAISE NOTICE '--------------------';

		/* =========== Loding crm_cust_info ============== */
		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;
		RAISE NOTICE 'Inserting Data Into: silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)
		SELECT
			cst_id,
			cst_key,
			TRIM(cst_firstname) AS cst_firstname,
			TRIM(cst_lastname) AS cst_lastname,
			CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				 WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				 ELSE 'n/a'
			END AS cst_marital_status,    -- Noramlize marital status values to readable format
			CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				 ELSE 'n/a'
			END AS cst_gndr,              -- Normalize gender values to readable format
			cst_create_date
		FROM(
			SELECT *,
			ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
			FROM bronze.crm_cust_info
			WHERE cst_id IS NOT NULL
		) 
		WHERE flag_last = 1;
		end_time := clock_timestamp();
		RAISE NOTICE 'Loading Time: % ms', ROUND(EXTRACT(EPOCH FROM end_time - start_time) * 1000);
		
		
		/* =========== crm_prd_info ============== */
		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		RAISE NOTICE 'Inserting Data Into: silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info(
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,   -- Extract Category ID
			SUBSTRING(prd_key, 7, LENGTH(prd_key)) AS prd_key,       -- Extract Product Key
			prd_nm,
			COALESCE(prd_cost, 0) AS prd_cost,
			CASE UPPER(TRIM(prd_line))
				 WHEN 'M' THEN 'Mountain'
			     WHEN 'R' THEN 'Road'
				 WHEN 'S' THEN 'Other Sales'
				 WHEN 'T' THEN 'Touring'
				 ELSE 'n/a'
			END AS prd_line,    -- Map Product line codes to descriptive values
			CAST(prd_start_dt AS DATE) AS prd_start_dt,
			CAST(LEAD(prd_start_dt) over (partition by prd_key order by prd_start_dt) - INTERVAL '1 day' AS DATE) as prd_end_dt -- Calculating End Date
		FROM bronze.crm_prd_info;
		end_time := clock_timestamp();
		RAISE NOTICE 'Loading Time: % ms', ROUND(EXTRACT(EPOCH FROM end_time - start_time) * 1000);
		
		
		/* =========== crm_sales_details ============== */
		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;
		RAISE NOTICE 'Inserting Data Into: silver.crm_sales_details';
		INSERT INTO silver.crm_sales_details(
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			CASE WHEN sls_order_dt < 0 OR LENGTH(sls_order_dt::TEXT) != 8 THEN NULL
				 ELSE TO_DATE(sls_order_dt::TEXT, 'YYYYMMDD')
			END AS sls_order_dt,
			CASE WHEN sls_ship_dt < 0 OR LENGTH(sls_ship_dt::TEXT) != 8 THEN NULL
				 ELSE TO_DATE(sls_ship_dt::TEXT, 'YYYYMMDD')
			END AS sls_ship_dt,
			CASE WHEN sls_due_dt < 0 OR LENGTH(sls_due_dt::TEXT) != 8 THEN NULL
				 ELSE TO_DATE(sls_due_dt::TEXT, 'YYYYMMDD')
			END AS sls_due_dt,
			CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price)
			 	 ELSE sls_sales
			END AS sls_sales,  -- Recalculate sales
			sls_quantity,
			CASE WHEN sls_price IS NULL OR sls_price <= 0 THEN ABS(sls_sales / NULLIF(sls_quantity, 0))
			 	 ELSE sls_price
			END AS sls_price  -- Drive price if original value is invalid
		FROM bronze.crm_sales_details;
		end_time := clock_timestamp();
		RAISE NOTICE 'Loading Time: % ms', ROUND(EXTRACT(EPOCH FROM end_time - start_time) * 1000);

		RAISE NOTICE '--------------------';
		RAISE NOTICE 'LOADING ERP TABLES';
		RAISE NOTICE '--------------------';
		
		/* =========== erp_cust_az12 ============== */
		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table: silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12;
		RAISE NOTICE 'Inserting Data Into: silver.erp_cust_az12';
		INSERT INTO silver.erp_cust_az12(
			cid,
			bdate,
			gen
		)
		SELECT
			CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))  -- Remove 'NAS' prefix if present
				 ELSE cid
			END AS cid,
			CASE WHEN bdate > CURRENT_DATE THEN NULL  -- Set future birthdates to NULL
				 ELSE bdate
			END AS bdate,
			CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
				 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
				 ELSE 'n/a'
			END AS gen   -- Normalize gender values and handle unknown cases
		FROM bronze.erp_cust_az12;
		end_time := clock_timestamp();
		RAISE NOTICE 'Loading Time: % ms', ROUND(EXTRACT(EPOCH FROM end_time - start_time) * 1000);
		
		
		/* =========== erp_loc_a101 ============== */
		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table: silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;
		RAISE NOTICE 'Inserting Data Into: silver.erp_loc_a101';
		INSERT INTO silver.erp_loc_a101(
			cid,
			cntry
		)
		SELECT
			replace(cid, '-', ''),
			CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
				 WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
				 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
				 ELSE TRIM(cntry)
			END AS cntry   -- Normalize and Handle missing or blank country codes
		FROM bronze.erp_loc_a101;
		end_time := clock_timestamp();
		RAISE NOTICE 'Loading Time: % ms', ROUND(EXTRACT(EPOCH FROM end_time - start_time) * 1000);
			
		
		/* =========== erp_px_cat_g1v2 ============== */
		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table: silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		RAISE NOTICE 'Inserting Data Into: silver.erp_px_cat_g1v2';
		INSERT INTO silver.erp_px_cat_g1v2(
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT 
			id,
			cat,
			subcat,
			maintenance
		FROM bronze.erp_px_cat_g1v2;
		end_time := clock_timestamp();
		RAISE NOTICE 'Loading Time: % ms', ROUND(EXTRACT(EPOCH FROM end_time - start_time) * 1000);
		RAISE NOTICE '=================================';
		RAISE NOTICE 'LOADING SILVER LAYER IS COMPLETED';
		RAISE NOTICE '=================================';
		batch_end_time := clock_timestamp();
		RAISE NOTICE 'Total Loading Duration: % ms', ROUND(EXTRACT(EPOCH FROM batch_end_time - batch_start_time) * 1000);
	EXCEPTION
		WHEN OTHERS THEN
    		RAISE WARNING 'Error occurred during silver load: %', SQLERRM;
	END;
END;
$$