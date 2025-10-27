
-- RETAIL BUSINESS PERFORMANCE & PROFITABILITY ANALYSIS


CREATE DATABASE IF NOT EXISTS retail;
USE retail;

DROP TABLE IF EXISTS sales, products, stores, inventory, date_dim;

CREATE TABLE products (
    product_id VARCHAR(20) PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    brand VARCHAR(50),
    supplier VARCHAR(50),
    reorder_point INT
);

CREATE TABLE stores (
    store_id VARCHAR(20) PRIMARY KEY,
    store_name VARCHAR(50),
    region VARCHAR(20),
    city VARCHAR(50)
);

CREATE TABLE date_dim (
    date DATE PRIMARY KEY,
    day INT,
    month INT,
    month_name VARCHAR(10),
    quarter INT,
    year INT,
    season VARCHAR(20)
);

CREATE TABLE sales (
    order_id VARCHAR(20),
    order_date DATE,
    product_id VARCHAR(20),
    store_id VARCHAR(20),
    quantity INT,
    unit_price DECIMAL(10,2),
    unit_cost DECIMAL(10,2),
    discount DECIMAL(10,2),
    revenue DECIMAL(12,2),
    cogs DECIMAL(12,2),
    profit DECIMAL(12,2),
    margin_pct DECIMAL(6,4),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (store_id) REFERENCES stores(store_id)
);

CREATE TABLE inventory (
    product_id VARCHAR(20),
    store_id VARCHAR(20),
    date DATE,
    on_hand_qty INT,
    avg_cost DECIMAL(10,2),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (store_id) REFERENCES stores(store_id)
);



LOAD DATA INFILE '"C:/Users/manoj/Downloads/retail_dataset/products.csv"'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA INFILE '"C:/Users/manoj/Downloads/retail_dataset/stores.csv"'
INTO TABLE stores
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA INFILE '"C:/Users/manoj/Downloads/retail_dataset/date_dim.csv"'
INTO TABLE date_dim
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA INFILE '"C:/Users/manoj/Downloads/retail_dataset/sales.csv"'
INTO TABLE sales
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA INFILE '"C:/Users/manoj/Downloads/retail_dataset/inventory.csv"'
INTO TABLE inventory
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- CLEAN NULL VALUES
UPDATE products SET brand = 'Unknown' WHERE brand IS NULL OR brand = '';
UPDATE stores SET region = 'Unknown' WHERE region IS NULL OR region = '';
UPDATE sales SET discount = 0 WHERE discount IS NULL;
UPDATE inventory SET avg_cost = 0 WHERE avg_cost IS NULL;

-- PROFIT MARGINS
SELECT 
    p.category,
    p.sub_category,
    ROUND(SUM(s.revenue),2) AS total_revenue,
    ROUND(SUM(s.cogs),2) AS total_cogs,
    ROUND(SUM(s.profit),2) AS total_profit,
    ROUND(SUM(s.profit)/NULLIF(SUM(s.revenue),0)*100,2) AS margin_percent
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.category, p.sub_category
ORDER BY total_profit DESC;

-- INVENTORY TURNOVER
SELECT 
    p.category,
    p.sub_category,
    ROUND(SUM(s.cogs),2) AS total_cogs,
    ROUND(AVG(i.on_hand_qty * i.avg_cost),2) AS avg_inventory_value,
    ROUND(SUM(s.cogs) / NULLIF(AVG(i.on_hand_qty * i.avg_cost),0),2) AS inventory_turnover
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN inventory i ON s.product_id = i.product_id
GROUP BY p.category, p.sub_category
ORDER BY inventory_turnover DESC;

-- SLOW MOVING PRODUCTS
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.sub_category,
    SUM(s.quantity) AS total_sold,
    AVG(i.on_hand_qty) AS avg_stock,
    ROUND(SUM(s.quantity)/NULLIF(AVG(i.on_hand_qty),0),2) AS sell_through_rate
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN inventory i ON s.product_id = i.product_id
GROUP BY p.product_id, p.product_name, p.category, p.sub_category
HAVING sell_through_rate < 0.3
ORDER BY sell_through_rate ASC;

-- OVERSTOCKED PRODUCTS
SELECT 
    p.category,
    p.sub_category,
    SUM(i.on_hand_qty) AS total_stock,
    SUM(s.quantity) AS total_sold,
    ROUND(SUM(s.quantity)/NULLIF(SUM(i.on_hand_qty),0)*100,2) AS demand_vs_stock_pct
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN inventory i ON s.product_id = i.product_id
GROUP BY p.category, p.sub_category
HAVING demand_vs_stock_pct < 40
ORDER BY demand_vs_stock_pct ASC;

SELECT 
    p.category, p.sub_category,
    ROUND(SUM(s.revenue),2) AS total_revenue,
    ROUND(SUM(s.profit),2) AS total_profit,
    ROUND(SUM(s.profit)/NULLIF(SUM(s.revenue),0)*100,2) AS margin_percent
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/profit_margin_summary.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.category, p.sub_category


