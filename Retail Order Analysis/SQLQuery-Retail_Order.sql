SELECT * FROM df_retail_order;

-- Top 10 product with high sales
SELECT TOP 10
product_id, SUM(sales) AS total_sales
FROM df_retail_order
GROUP BY product_id
ORDER BY total_sales DESC;

-- Top 5 high selling product by region
WITH CTE AS 
(SELECT 
region, product_id, SUM(sales) AS total_sales
FROM df_retail_order
GROUP BY region, product_id
)

SELECT * FROM 
(
SELECT *,
ROW_NUMBER () OVER (PARTITION BY region ORDER BY total_sales DESC) AS row_num
FROM CTE
) CTE2

WHERE row_num <=5;

-- Month over Month  2022 vs 2023 sales
WITH CTE AS
(
SELECT YEAR(order_date) years,
		MONTH(order_date) months,
		SUM(sales) AS total_sales
FROM df_retail_order
GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT months,
SUM (CASE WHEN years =2022 THEN total_sales ELSE NULL END) AS '2022_sales',
SUM (CASE WHEN years =2023 THEN total_sales ELSE NULL END) AS '2023_sales'
FROM CTE
GROUP BY months
ORDER BY months
;

-- Highest Sales Month for each category

WITH CTE AS
(SELECT 
	category,
	FORMAT(order_date,'yyyyMM') AS months,
	SUM(sales) AS total_sales
FROM df_retail_order
GROUP BY category, FORMAT(order_date,'yyyyMM')
)

SELECT * FROM
(SELECT *,
ROW_NUMBER () OVER (PARTITION BY category ORDER BY total_sales DESC) AS row_num
FROM CTE
) CTE2
WHERE row_num =1
;
