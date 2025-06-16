/*
======================================================
STORED PROCEDURE: LOAD BRONZE LAYER (SOURCE -> BRONZE)
======================================================
Scripts Purpose:
	This stored procedure loads data into the BRONZE schema from external CSV files.
Performed Actions:
	- Set datestyle
	- Truncate the tables before loading
	- Use 'COPY' command to load the data.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
	CALL bronze.load_bronze();
*/

/*
NOTE: 
	The default DateStyle in PostgreSQL is usually: ISO, MDY (i.e., month-day-year)
	So, work with the exact datetime we need to SET datestyle.
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE 
	start_time TIMESTAMP;
	end_time TIMESTAMP;
	batch_start_time TIMESTAMP;
	batch_end_time TIMESTAMP;
BEGIN
	RAISE NOTICE 'Changing DateStyle';
	SET datestyle = 'DMY';

	BEGIN
		batch_start_time := clock_timestamp();
		RAISE NOTICE '====================';
		RAISE NOTICE 'LOADING BRONZE LAYER';
		RAISE NOTICE '====================';
		RAISE NOTICE '--------------------';
		RAISE NOTICE 'LOADING CRM TABLES';
		RAISE NOTICE '--------------------';

		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;
		
		RAISE NOTICE 'Inserting Data Into: bronze.crm_cust_info';
		COPY bronze.crm_cust_info 
		FROM '/csv_files/cust_info.csv'
		DELIMITER ','
		CSV HEADER;
		
		RAISE NOTICE 'Deleting last data from bronze.crm_cust_info: No NEED';
		DELETE FROM bronze.crm_cust_info
		WHERE ctid = (
			SELECT ctid FROM bronze.crm_cust_info
			ORDER BY ctid DESC
			LIMIT 1
		);
		end_time := clock_timestamp();
		RAISE NOTICE 'Loading Time: % ms', ROUND(EXTRACT(EPOCH FROM end_time - start_time) * 1000);

		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;
		
		RAISE NOTICE 'Inserting Data Into: bronze.crm_prd_info';
		COPY bronze.crm_prd_info 
		FROM '/csv_files/prd_info.csv'
		DELIMITER ','
		CSV HEADER;
		end_time := clock_timestamp();
		RAISE NOTICE 'Loading Time: % ms', ROUND(EXTRACT(EPOCH FROM end_time - start_time) * 1000);

		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
		
		RAISE NOTICE 'Inserting Data Into: bronze.crm_sales_details';
		COPY bronze.crm_sales_details 
		FROM '/csv_files/sales_details.csv'
		DELIMITER ','
		CSV HEADER;
		end_time := clock_timestamp();
		RAISE NOTICE 'Loading Time: % ms', ROUND(EXTRACT(EPOCH FROM end_time - start_time) * 1000);

		RAISE NOTICE '--------------------';
		RAISE NOTICE 'LOADING ERP TABLES';
		RAISE NOTICE '--------------------';

		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;
		
		RAISE NOTICE 'Inserting Data Into: bronze.erp_cust_az12';
		COPY bronze.erp_cust_az12 
		FROM '/csv_files/CUST_AZ12.csv'
		DELIMITER ','
		CSV HEADER;
		end_time := clock_timestamp();
		RAISE NOTICE 'Loading Time: % ms', ROUND(EXTRACT(EPOCH FROM end_time - start_time) * 1000);

		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;
		
		RAISE NOTICE 'Inserting Data Into: bronze.erp_loc_a101';
		COPY bronze.erp_loc_a101 
		FROM '/csv_files/LOC_A101.csv'
		DELIMITER ','
		CSV HEADER;
		end_time := clock_timestamp();
		RAISE NOTICE 'Loading Time: % ms', ROUND(EXTRACT(EPOCH FROM end_time - start_time) * 1000);

		start_time := clock_timestamp();
		RAISE NOTICE 'Truncating Table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		
		RAISE NOTICE 'Inserting Data Into: bronze.erp_px_cat_g1v2';
		COPY bronze.erp_px_cat_g1v2 
		FROM '/csv_files/PX_CAT_G1V2.csv'
		DELIMITER ','
		CSV HEADER;
		end_time := clock_timestamp();
		RAISE NOTICE 'Loading Time: % ms', ROUND(EXTRACT(EPOCH FROM end_time - start_time) * 1000);
		
		RAISE NOTICE '================================';
		RAISE NOTICE 'LOADING BRONZE LAYER IS COMPLETE';
		RAISE NOTICE '================================';
		batch_end_time := clock_timestamp();
		RAISE NOTICE 'Total Loading Duration: % ms', ROUND(EXTRACT(EPOCH FROM batch_end_time - batch_start_time) * 1000);
	EXCEPTION
  		WHEN OTHERS THEN
    		RAISE WARNING 'Error occurred during bronze load: %', SQLERRM;
	END;
END;
$$;