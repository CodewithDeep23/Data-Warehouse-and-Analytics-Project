/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWareHouse'. 
    Additionally, it sets up three schemas within the database: 
    'bronze', 'silver', and 'gold'—commonly used in Medallion Architecture.

Instructions:
    1. Connect to the PostgreSQL server using a superuser or a user with permission to create databases:
        Example:
            $ psql -U postgres

    2. Run this script using the following command:
        \i path/to/init_database.sql

    3. After creating the database, switch to it using:
        \c "DataWareHouse"

Note:
    - PostgreSQL database and schema names are case-insensitive unless quoted.
    - Schema creation should be done **after switching** to the new database.
=============================================================
*/

-- Step 1: Create the 'DataWareHouse' database
CREATE DATABASE DataWareHouse;

-- Step 2: Connect to the 'DataWareHouse' database before creating schemas
-- This line is only for clarity; must be executed manually or via a separate script if needed.
-- \c "DataWareHouse"

-- Step 3: Create schemas inside 'DataWareHouse'
-- IMPORTANT: Ensure you're connected to "DataWareHouse" before running the following

CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;