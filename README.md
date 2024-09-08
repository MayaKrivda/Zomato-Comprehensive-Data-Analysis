# Comprehensive Data Analysis using SQL - Zomato (A Food Delivery Company)

This repository contains a SQL-based data analysis project focused on key business metrics for a food delivery company. The project involves exploratory data analysis (EDA) using PostgreSQL to answer 20 specific business questions related to customer behavior, restaurant performance, rider efficiency, and operational insights.

## Project Structure

### Topics Covered
The project explores various SQL topics, including:

 **Data Retrieval and Filtering**: SQL queries to retrieve and filter data.
- **Aggregations and Grouping**: Use of `COUNT()`, `SUM()`, and `AVG()` to aggregate data.
- **Joining Tables**: Combining data from multiple tables using `LEFT JOIN`.
- **Window Functions**: Utilization of `ROW_NUMBER()`, `DENSE_RANK()`, and `LAG()` to analyze ranked data.
- **Date and Time Functions**: Manipulating timestamps for business insights.
- **Conditional Logic**: Use of `CASE` statements for data segmentation.
- **Subqueries**: Nested queries to derive complex metrics.
- **Ranking and Ordering**: Applying various ranking techniques to categorize data based on performance.
- **Data Segmentation**: Use of conditional logic (`CASE STATEMENT`) for dividing data into meaningful categories.

### Problem Solving & Decision Making

1. **Customer Behavior and Insights**: Understanding customer order patterns, preferences and churn rates.
2. **Order and Sales Analysis**: Evaluating order volumes, peak times, and revenue generation.
3. **Restaurant Performance**: Analysis of restaurant revenue ranking, cancellation rate comparison and monthly growth ratio.
4. **Rider Efficiency and Performance**: Metrics on delivery time, ratings, monthly earning and efficiency.


## Files in the Repository

- **CSV Files**: Containing raw data for analysis.
  - `customers.csv`
  - `deliveries.csv`
  - `orders.csv`
  - `restaurants.csv`
  - `riders.csv`
  
- **ERD.pgerd**: Entity Relationship Diagram (ERD) file providing a visual representation of the database schema.

- **PostgreSQL Files**:
  - `creation_of_tables.sql`: SQL script for creating the database tables and defining relationships.
  - `EDA.sql`: SQL queries for exploratory data analysis (EDA), including data extraction, manipulation, and insights generation.
