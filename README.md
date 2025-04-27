# SQL-Data_Analytics_Project

# 📊 Sales Database Analysis and Reporting

This repository contains SQL scripts for performing exploratory data analysis (EDA), business data analysis, and generating reporting views based on a sales database I developed in a previous project.
The scripts are organized into three main parts, each serving a different analytical or reporting purpose.

---

## 1. Exploratory Data Analysis (EDA)

**Objective:**  
Perform an initial exploration of the sales database to understand its structure, key dimensions, time coverage, and fundamental business metrics.

**Key Sections:**
- **Database Structure Exploration**: List all tables and columns.
- **Dimensions Exploration**: Explore countries, product categories, and subcategories.
- **Date Exploration**: Analyze order date ranges and customer age distributions.
- **Measures Exploration**: Summarize key metrics such as total sales, quantity, orders, products, and customers.
- **Magnitude Analysis**: Compare metrics across countries, genders, and categories.
- **Ranking Analysis**: Identify top and bottom products and customers by revenue or order counts.
  
📂 **Script:** [script/EDA.sql](script/EDA.sql)

---

## 2. Business Data Analysis

**Objective:**  
Analyze sales trends over time, cumulative growth, product performance, contribution by category, and segment customers/products based on behavior.

**Key Sections:**
- **Change Over Time**: Track monthly sales volume, number of customers, and quantities sold.
- **Cumulative Analysis**: Calculate yearly sales and cumulative sales growth.
- **Performance Analysis**: Compare yearly product performance with averages and previous years.
- **Part-to-Whole Analysis**: Assess category contributions to total sales, yearly and overall.
- **Data Segmentation**: Segment customers by spending behavior and products by cost ranges.

📂 **Script:** [script/Data Analysis.sql](script/Data_Analysis.sql)

---

## 3. Reporting Views

**Objective:**  
Create reusable reporting views to consolidate customer and product performance metrics for business intelligence purposes.

**Reports Created:**
- **Customer Report (`gold.report_customers`)**
  - Customer segmentation (VIP, Regular, New)
  - Customer metrics: orders, sales, quantities, lifespan, recency, AOV, monthly spend
- **Product Report (`gold.report_products`)**
  - Product segmentation (High-Performer, Mid-Performer, Low-Performer)
  - Product metrics: orders, sales, customers, lifespan, recency, AOR, monthly revenue

📂 **Script:** [script/Report.sql](script/Report.sql)

---

## 📈 Tools & Technologies

- SQL Server 
- Analytical SQL (Aggregations, Window Functions, CTEs)
- Business Intelligence Metrics (KPIs, Segmentation)

---

## 🔖 About This Project

This project was developed to strengthen hands-on SQL skills in data exploration, trend analysis, and reporting view generation within a business context.  
It simulates a real-world data analytics workflow — from understanding raw datasets to delivering structured insights and ready-to-use reporting tables.

