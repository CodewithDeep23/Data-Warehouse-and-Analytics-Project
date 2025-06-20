# 📚 Data Catalog: Gold Layer

## Overview
The Gold Layer is the business-level data representation, structured to support analytical and reporting use cases. It consists of **dimension tables** and **fact tables** for specific business metrics.

---

### 1. **gold.dim_customers**
**Purpose:** Stores customer details enriched with demographic and geographic data.

| Column Name      | Data Type     | Description                                                                                   |
|------------------|---------------|-----------------------------------------------------------------------------------------------|
| `customer_key`     | INTEGER       | Surrogate key uniquely identifying each customer record in the dimension table.               |
| `customer_id`      | INTEGER       | Unique numerical identifier assigned to each customer.                                        |
| `customer_number`  | VARCHAR(50)   | Alphanumeric identifier representing the customer, used for tracking and referencing.         |
| `first_name`       | VARCHAR(50)   | The customer's first name, as recorded in the system.                                         |
| `last_name`        | VARCHAR(50)   | The customer's last name or family name.                                                      |
| `country`          | VARCHAR(50)   | The country of residence for the customer (e.g., 'Australia').                                |
| `marital_status`   | VARCHAR(50)   | The marital status of the customer (e.g., 'Married', 'Single').                               |
| `gender`           | VARCHAR(50)   | The gender of the customer (e.g., 'Male', 'Female', 'n/a').                                   |
| `birthdate`        | DATE          | The date of birth of the customer, formatted as YYYY-MM-DD (e.g., 1971-10-06).                |
| `create_date`      | DATE          | The date and time when the customer record was created in the system.                         |

---

### 2. **gold.dim_products**
**Purpose:** Provides information about the products and their attributes.

| Column Name          | Data Type     | Description                                                                                   |
|----------------------|---------------|-----------------------------------------------------------------------------------------------|
| `product_key`          | INTEGER       | Surrogate key uniquely identifying each product record in the dimension table.                |
| `product_id`           | INTEGER       | Unique identifier assigned to the product for internal tracking.                              |
| `product_number`       | VARCHAR(50)   | Alphanumeric code representing the product.                                                   |
| `product_name`         | VARCHAR(50)   | Descriptive name of the product, including type, color, and size.                             |
| `category_id`          | VARCHAR(50)   | Identifier for the product's category.                                                        |
| `category`             | VARCHAR(50)   | High-level classification of the product (e.g., Bikes, Components).                           |
| `subcategory`          | VARCHAR(50)   | Detailed classification of the product within the category.                                   |
| `maintenance_required` | VARCHAR(50)   | Indicates if the product requires maintenance (e.g., 'Yes', 'No').                            |
| `cost`                 | INTEGER       | Base cost of the product, in monetary units.                                                  |
| `product_line`         | VARCHAR(50)   | Product line or series (e.g., Road, Mountain).                                                |
| `start_date`           | DATE          | The date the product became available for sale or use.                                        |

---

### 3. **gold.fact_sales**
**Purpose:** Stores transactional sales data for analytical purposes.

| Column Name     | Data Type     | Description                                                                                   |
|-----------------|---------------|-----------------------------------------------------------------------------------------------|
| `order_number`    | VARCHAR(50)   | Unique identifier for each sales order (e.g., 'SO54496').                                     |
| `product_key`     | INTEGER       | Surrogate key referencing the product dimension.                                               |
| `customer_key`    | INTEGER       | Surrogate key referencing the customer dimension.                                              |
| `sales_amount`    | INTEGER       | Total sales amount for the line item, in whole currency units.                                |
| `quantity`        | INTEGER       | Number of units sold.                                                                         |
| `price`           | INTEGER       | Price per unit of the product.                                                                |
| `order_date`      | DATE          | The date when the order was placed.                                                           |
| `shipping_date`   | DATE          | The date when the order was shipped.                                                          |
| `due_date`        | DATE          | The date the order was due.                                                                   |