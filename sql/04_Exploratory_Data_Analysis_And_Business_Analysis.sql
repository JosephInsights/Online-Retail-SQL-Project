/*====================================================================
  PROJECT: ONLINE RETAIL SALES ANALYSIS

  PHASE 4: EXPLORATORY DATA ANALYSIS (EDA) AND BUSINESS ANALYSIS

  DATABASE: OnlineRetailAnalytics
  SOURCE TABLE: dbo.online_retail_clean

  PHASE OBJECTIVE:
  Analyze the cleaned online retail dataset to identify sales trends,
  revenue performance, product performance, customer purchasing
  behaviour, geographical patterns, and operational insights.

  KEY ANALYSIS AREAS:
  1. Overall Sales and Revenue Performance
  2. Product Performance Analysis
  3. Customer Purchasing Behaviour
  4. Geographical Sales Analysis
  5. Time-Based Sales Trends
  6. Returns, Cancellations and Adjustments
  7. Business Insights and Recommendations

  CURRENCY: British Pound Sterling (GBP)
  CURRENCY SYMBOL: £

    /*NOTE:
	All financial calculations are expressed in GBP.
	No currency conversion is applied. 
	*/


  APPROACH:
  SQL-based analysis using aggregations, joins, CTEs, subqueries,
  window functions, and other relevant SQL techniques.

====================================================================*/


-- Phase 4.1 – REVENUE DEFINITION AND CLASSIFICATION
----------------------------------------------------------------------

         -- 4.1.1 Inspect Transaction Classification

SELECT 
	CASE WHEN InvoiceNo LIKE 'C%' THEN 'Cancelled'
		 WHEN InvoiceNo LIKE 'A%' THEN 'Adjusted'
		 ELSE 'Regular'
	END AS TransactionType,
	COUNT (*) AS TotalRecords,
	COUNT (DISTINCT InvoiceNo) AS TotalInvoices,
	SUM (Quantity * UnitPrice) AS TransactionValue
FROM dbo.online_retail_clean
GROUP BY 
		CASE 
			WHEN InvoiceNo LIKE 'C%' THEN 'Cancelled'
			WHEN InvoiceNo LIKE 'A%' THEN 'Adjusted'
			ELSE 'Regular'
		END
ORDER BY TransactionValue DESC;


/*
FINDINGS:
1. Classified 536,641 records into three transaction categories.
2. Regular transactions: 527,387 records across 22,061 invoices.
3. Cancellation transactions: 9,251 records across 3,836 invoices.
4. Adjustment transactions: 3 records across 3 invoices.
5. Regular transaction value: 10,631,048.744.
6. Cancellation value: -893,979.730.
7. Adjustment value: -11,062.060.

ACTIONS:
1. Classified transactions using invoice number prefixes.
2. Separated regular sales, cancellations, and adjustments.
3. Retained all transaction categories for analysis.
4. No records modified or deleted.
*/


      -- 4.1.2 Calculate Overall Transaction Value

SELECT 
	SUM (CASE WHEN InvoiceNo NOT LIKE 'C%' AND InvoiceNo NOT LIKE 'A%' THEN Quantity * UnitPrice ELSE 0 END ) AS RegularSalesValue,
	SUM (CASE WHEN InvoiceNo LIKE 'C%' THEN Quantity * UnitPrice ELSE 0 END ) AS CancelledSalesValue,
	SUM (CASE WHEN InvoiceNo LIKE 'A%' THEN Quantity * UnitPrice ELSE 0 END ) AS AdjustedSalesValue,
	SUM (Quantity * UnitPrice) AS NetTransaction
FROM dbo.online_retail_clean;


/*
FINDINGS:
1. Regular sales value: 10,631,048.744.
2. Cancellation value: -893,979.730.
3. Adjustment value: -11,062.060.
4. Net transaction value: 9,726,006.954.

ACTIONS:
1. Calculated transaction values using Quantity * UnitPrice.
2. Separated regular sales, cancellations, and adjustments.
3. Established net transaction value after accounting for
   cancellations and adjustments.
4. Retained the original transaction records.
*/

     -- 4.1.3 Calculate the Overall Business Performance KPIs

SELECT 
	CAST (SUM (Quantity * UnitPrice) AS decimal (18,2) ) AS TotalRevenue,
	COUNT (DISTINCT InvoiceNo) AS TotalOrders,
	SUM (Quantity) AS TotalNetQuantity,
	COUNT (DISTINCT CustomerID) AS TotalCustomers,
	CAST (SUM (Quantity * UnitPrice) / NULLIF(COUNT (DISTINCT InvoiceNo),0) AS decimal (18,2)) AS AverageOrderValue
FROM dbo.online_retail_clean
WHERE InvoiceNo NOT LIKE 'C%' AND InvoiceNo NOT LIKE 'A%';


/*
FINDINGS:
1. Total regular sales revenue was £10,631,048.74.
2. The business processed 22,061 regular invoices.
3. Total net quantity was 5,438,059 units.
4. Identified 4,339 distinct customers with available CustomerIDs.
5. Average Order Value was £481.89.

ACTIONS:
1. Established the overall business performance KPIs.
2. Excluded cancellation and adjustment invoices.
3. Excluded missing CustomerIDs from the distinct customer count.
4. Established baseline metrics for subsequent business analysis.
*/




		-- PHASE 4.2 SALES PERFORMANCE ANALYSIS
	----------------------------------------------------------------------------

-- 4.2.1 Monthly Revenue and Order Performance 

SELECT 
	YEAR (InvoiceDate) AS SalesYear,
	MONTH (InvoiceDate) AS SalesMonth,
	CAST (SUM (Quantity * UnitPrice) AS decimal (18,2)) AS MonthlyRevenue_GBP,
	COUNT (DISTINCT InvoiceNo) AS TotalOrders,
	SUM (Quantity) AS NetQuantity
FROM dbo.online_retail_clean
WHERE InvoiceNo NOT LIKE 'C%' AND InvoiceNo NOT LIKE 'A%'
GROUP BY 
	YEAR (InvoiceDate), 
	MONTH (InvoiceDate)
ORDER BY 
	SalesYear,
	SalesMonth;


/*
FINDINGS:
1. November 2011 recorded the highest monthly revenue of
   £1,503,866.78.
2. February 2011 recorded the lowest revenue among complete
   months at £522,545.56.
3. November 2011 recorded the highest order volume of 3,021.
4. November 2011 also recorded the highest net quantity
   of 749,777 units.
5. Revenue increased substantially between September and
   November 2011.
6. December 2010 and December 2011 are incomplete months.

ACTIONS:
1. Summarized monthly revenue, orders and net quantity.
2. Identified the strongest and weakest complete months.
3. Flagged incomplete months to avoid misleading comparisons.
4. No source records modified.
*/


-- 4.2.2 Calculate Month-Over-Month Revenue Growth

WITH MonthlySales AS 
(
	SELECT 
		YEAR (InvoiceDate) AS SalesYear,
		MONTH (InvoiceDate) AS SalesMonth,
		SUM (Quantity * UnitPrice) AS TotalMonthlyRevenue
	FROM dbo.online_retail_clean
	WHERE InvoiceNo NOT LIKE 'C%' AND InvoiceNo NOT LIKE 'A%'
	GROUP BY 
		YEAR (InvoiceDate),
		MONTH (InvoiceDate)
),
PreviousMonth AS 
(
SELECT *,
	LAG (TotalMonthlyRevenue) OVER (ORDER BY SalesYear,SalesMonth) AS PreviousMonthlySales
FROM MonthlySales
)

SELECT 
	SalesYear,
	SalesMonth,
	CAST (TotalMonthlyRevenue AS DECIMAL (18,2)) AS MonthlyRevenue_GBP,
	CAST (PreviousMonthlySales AS decimal (18,2)) AS PreviousMonthlyRevenue_GBP,
	CAST ((TotalMonthlyRevenue - PreviousMonthlySales) * 100.0 / NULLIF (PreviousMonthlySales,0) AS DECIMAL (18,2))AS PercentageGrowth
FROM PreviousMonth;

/*
FINDINGS:
1. May 2011 recorded the highest monthly revenue growth at 43.27%.
2. September 2011 recorded revenue growth of 41.47%.
3. April 2011 recorded the largest decline among complete months
   at 25.03%.
4. November 2011 recorded revenue growth of 30.63%.
5. December 2011 recorded a decline of 57.59%, but the month
   is incomplete.
6. December 2010 has no previous month comparison.

ACTIONS:
1. Used the LAG() window function to retrieve previous-month revenue.
2. Calculated monthly revenue growth percentages.
3. Identified periods of significant growth and decline.
4. Flagged incomplete months to avoid misleading conclusions.
*/


-- 4.2.3 Quarterly Revenue Performance 

SELECT 
	YEAR (InvoiceDate) AS YearlySales,
	DATEPART (QUARTER,InvoiceDate) AS SalesQuater,
	CAST (SUM (Quantity * UnitPrice)AS decimal (18,2)) AS QuartelyRevenue_GBP,
	COUNT (DISTINCT InvoiceNo) AS TotalOrders,
	SUM (Quantity) AS NetQuantitySold
FROM dbo.online_retail_clean
WHERE InvoiceNo NOT LIKE 'C%' AND InvoiceNo NOT LIKE 'A%'
GROUP BY 
	YEAR (InvoiceDate),
	DATEPART (QUARTER,InvoiceDate)
ORDER BY 
	YearlySales,
	SalesQuater;

/*
FINDINGS:
1. 2011 Q3 recorded the highest revenue among complete quarters
   at £2,521,290.63.
2. 2011 Q1 recorded the lowest revenue among complete quarters
   at £1,928,572.43.
3. Revenue increased across Q1, Q2 and Q3 of 2011.
4. 2011 Q4 recorded the highest observed revenue of
   £3,292,920.84, but the quarter is incomplete.
5. Both 2010 Q4 and 2011 Q4 are incomplete reporting periods.

ACTIONS:
1. Analyzed quarterly revenue, orders and net quantity.
2. Identified the strongest and weakest complete quarters.
3. Flagged incomplete quarters to avoid misleading comparisons.
4. Retained all transaction records.
*/


-- 4.2.4 Quaterly Revenue Growth 

WITH TotalQuarterSales AS 
(
SELECT 
	YEAR (InvoiceDate) AS SalesYear,
	DATEPART (QUARTER,InvoiceDate) AS SalesQuarter,
	CAST (SUM (Quantity * UnitPrice) AS DECIMAL (18,2)) AS QuarterlyRevenue_GBP
FROM dbo.online_retail_clean
WHERE InvoiceNo NOT LIKE 'C%' AND InvoiceNo NOT LIKE 'A%'
GROUP BY 
	YEAR (InvoiceDate),
	DATEPART (QUARTER,InvoiceDate)
),
PreviousQuaterSales AS 
(
SELECT *,
	LAG (QuarterlyRevenue_GBP) OVER (ORDER BY SalesYear,SalesQuarter) AS PreviousSales
FROM TotalQuarterSales

)

SELECT *,
	CAST ((QuarterlyRevenue_GBP - 	PreviousSales) * 100.0 / NULLIF (PreviousSales,0) AS decimal (18,2)) AS PercentageGrowth
FROM PreviousQuaterSales;


/*
FINDINGS:
1. Q1 2011 recorded revenue growth of 134.78% compared with Q4 2010.
2. Q2 2011 recorded revenue growth of 7.17% compared with Q1 2011.
3. Q3 2011 recorded revenue growth of 21.99% compared with Q2 2011.
4. Q4 2011 recorded revenue growth of 30.60% compared with Q3 2011.
5. Revenue increased consistently across all four quarters of 2011.
6. Q3 and Q4 recorded stronger growth compared with Q2.
7. Q1 2011's growth is influenced by the incomplete Q4 2010 comparison, while Q4 2011 is also incomplete.

ACTIONS:
1. Used the LAG() window function to compare quarterly revenue.
2. Calculated quarter-over-quarter revenue growth percentages.
3. Identified periods of increasing revenue performance.
4. Retained all available quarterly results for subsequent analysis.
5. Documented incomplete reporting periods to guide interpretation.
*/




                   -- 4.3 PRODUCT PERFORMANCE ANALYSIS
-------------------------------------------------------------------------------

-- 4.3.1 Top 10 Products by Revenue 

SELECT TOP 10
	StockCode,
	Description,
	CAST (SUM (Quantity * UnitPrice) AS decimal (18,2)) AS TotalRevenue_GBP,
	SUM (Quantity) AS NetQuantitySold,
	COUNT(DISTINCT InvoiceNo) AS TotalOrders
FROM dbo.online_retail_clean
WHERE InvoiceNo NOT LIKE 'C%' AND InvoiceNo NOT LIKE 'A%'
GROUP BY 
	StockCode,
	Description
ORDER BY TotalRevenue_GBP DESC;


/*
FINDINGS:
1. DOTCOM POSTAGE recorded the highest transaction value
   at £206,248.77.
2. REGENCY CAKESTAND 3 TIER was the highest-revenue
   physical product in the results at £174,156.54.
3. PAPER CRAFT, LITTLE BIRDIE ranked third at £168,469.60.
4. Other high-revenue products included WHITE HANGING
   HEART T-LIGHT HOLDER and PARTY BUNTING.
5. The results included non-merchandise entries such as
   postage and manual transactions.

ACTIONS:
1. Ranked the top 10 StockCode and Description combinations
   by transaction value.
2. Identified leading revenue-generating products and
   non-merchandise transaction entries.
3. Flagged non-merchandise entries for separate treatment
   in subsequent product analysis.
*/


-- 4.3.2 Top 10 Physical Products by Revenue

SELECT TOP 10
	StockCode,
	Description,
	CAST (SUM (Quantity * UnitPrice) AS decimal (18,2)) AS SalesRevenue_GBP,
	COUNT (DISTINCT InvoiceNo) AS TotalOrders,
	SUM (Quantity) AS NetQuantitySold
FROM dbo.online_retail_clean
WHERE InvoiceNo NOT LIKE 'C%' AND InvoiceNo NOT LIKE 'A%'
	  AND StockCode NOT IN ('DOT','M','POST')
GROUP BY 
	StockCode,
	Description
ORDER BY SalesRevenue_GBP DESC;


/*
FINDINGS:
1. REGENCY CAKESTAND 3 TIER generated the highest revenue
   at GBP 174,156.54.
2. PAPER CRAFT, LITTLE BIRDIE ranked second with revenue
   of GBP 168,469.60.
3. WHITE HANGING HEART T-LIGHT HOLDER recorded the highest
   order frequency at 2,260 orders.
4. JUMBO BAG RED RETROSPOT appeared in 2,092 orders.
5. PAPER CRAFT, LITTLE BIRDIE recorded 80,995 net units
   in only one order, indicating an unusual transaction
   requiring further investigation.

ACTIONS:
1. Excluded postage and manual transaction codes.
2. Ranked physical product entries by revenue.
3. Identified leading products by revenue and order frequency.
4. Flagged the unusually high quantity for further investigation.
5. No source records modified.
*/

-- 4.3.3 Top 10 products by Quantity Sold 

SELECT TOP 10
	StockCode,
	Description,
	SUM (Quantity * UnitPrice) AS SalesRevenue,
	COUNT (DISTINCT InvoiceNo) AS TotalOrders,
	SUM (Quantity) AS NetQuantitySold
FROM dbo.online_retail_clean
WHERE InvoiceNo NOT LIKE 'A%' AND InvoiceNo NOT LIKE 'C%'
	  AND StockCode NOT IN ('M','DOT','POST')
GROUP BY 
	StockCode,
	Description
ORDER BY 
	NetQuantitySold DESC;


/*
FINDINGS:
1. PAPER CRAFT, LITTLE BIRDIE recorded the highest net
   quantity sold at 80,995 units.
2. MEDIUM CERAMIC TOP STORAGE JAR ranked second with
   78,033 units across 247 orders.
3. WORLD WAR 2 GLIDERS ASSTD DESIGNS ranked third
   with 54,951 units.
4. JUMBO BAG RED RETROSPOT recorded 48,375 units
   across 2,092 orders.
5. WHITE HANGING HEART T-LIGHT HOLDER had the highest
   order frequency among the top 10 products at 2,260 orders.
6. Product rankings by quantity differ from rankings by revenue.
7. PAPER CRAFT, LITTLE BIRDIE recorded an unusually high
   quantity in one order, requiring further investigation.

ACTIONS:
1. Ranked physical product entries by net quantity sold.
2. Excluded postage and manual transaction codes.
3. Compared quantity sold, revenue and order frequency.
4. Flagged unusual transaction volume for further investigation.
5. No source records modified.
*/


-- 4.3.4 Product Revenue Contribution

WITH ProductSales AS 
(
SELECT 
	StockCode,
	Description,
	CAST (SUM (Quantity * UnitPrice) AS decimal (18,2))AS TotalRevenue_GBP
FROM dbo.online_retail_clean
WHERE InvoiceNo NOT LIKE 'C%' AND InvoiceNo NOT LIKE 'A%' AND StockCode NOT IN ('M','DOT','POST')
GROUP BY 
	StockCode,
	Description
),
RevenueContribution AS 
(
SELECT *,
	SUM (TotalRevenue_GBP) OVER () AS OverallSales_GBP 
FROM ProductSales
)

SELECT TOP 10 *,
	CAST (TotalRevenue_GBP * 100.0 / NULLIF (OverallSales_GBP ,0) AS decimal (18,2)) AS RevenueContributionPercentage
FROM RevenueContribution
ORDER BY TotalRevenue_GBP DESC;


/*
FINDINGS:
1. Total physical product revenue amounted to GBP 10,268,945.27.
2. REGENCY CAKESTAND 3 TIER contributed the highest revenue
   share at 1.70%.
3. PAPER CRAFT, LITTLE BIRDIE ranked second, contributing 1.64%.
4. WHITE HANGING HEART T-LIGHT HOLDER contributed 1.03%.
5. The top 10 products accounted for approximately 9.44%
   of total physical product revenue.
6. Revenue contribution was distributed across many
   different products.

ACTIONS:
1. Calculated revenue for each StockCode and Description combination.
2. Used SUM() OVER() to calculate total product revenue.
3. Calculated each product's percentage contribution.
4. Ranked products by revenue contribution.
5. No source records modified.
*/


      -- 4.4 CUSTOMER PERFORMANCE ANALYSIS
-------------------------------------------------------------------------------

-- 4.4.1 Top 10 Customers by Revenue 

SELECT TOP 10
	CustomerID,
	SUM (Quantity * UnitPrice) AS TotalRevenue_GBP,
	COUNT (DISTINCT InvoiceNo) AS TotalOrders,
	SUM (Quantity) AS NetQuantitySold
FROM dbo.online_retail_clean
WHERE CustomerID IS NOT NULL AND InvoiceNo NOT LIKE 'C%' AND InvoiceNo NOT LIKE 'A%' AND StockCode NOT IN ('M','DOT','POST')
GROUP BY CustomerID
ORDER BY TotalRevenue_GBP DESC;


/*
FINDINGS:
1. Customer 14646 generated the highest revenue (£279,138.02).
2. Customer 18102 ranked second (£259,657.30).
3. Customer 17450 ranked third (£194,390.79).
4. Customer 14911 recorded the highest order count (199).
5. Customer 16446 generated £168,472.50 from only 2 orders.
6. Customer 12346 generated £77,183.60 from 1 order.

ACTIONS:
1. Ranked customers by total revenue in descending order.
2. Excluded cancelled and adjusted transactions.
3. Excluded service-related stock codes and missing CustomerIDs.
4. No data modifications required.
*/


-- 4.4.2 Customer Revenue and Order Frequency Segmentation

WITH CustomerSummary AS 
(
SELECT 
	CustomerID,
	SUM (Quantity * UnitPrice) AS TotalRevenue_GBP,
	COUNT (DISTINCT InvoiceNo) AS TotalOrders
FROM dbo.online_retail_clean
WHERE CustomerID IS NOT NULL AND InvoiceNo NOT LIKE 'C%' AND InvoiceNo NOT LIKE 'A%' AND StockCode NOT IN ('M','DOT','POST')
GROUP BY CustomerID
),

CustomerSegment AS 
(
SELECT *,
NTILE (4) OVER (ORDER BY TotalRevenue_GBP DESC) AS RevenueQuartile
FROM CustomerSummary
)

SELECT 
	CASE RevenueQuartile
		WHEN 1 THEN 'Top 25% Customers'
		WHEN 2 THEN 'Upper-Middle 25% Customers'
		WHEN 3 THEN 'Lower-Middle 25% Customers'
		WHEN 4 THEN 'Bottom 25% Customer'
	END AS CustomerSegments,
	COUNT (*) AS TotalCustomers,
	CAST (AVG (TotalRevenue_GBP) AS DECIMAL (18,2)) AS Avg_Revenue,
	CAST (AVG (TotalOrders) AS DECIMAL (18,2)) AS Avg_TotalOrders,
	CAST (SUM (TotalRevenue_GBP) AS decimal (18,2)) AS SegmentRevenue
FROM CustomerSegment
GROUP BY RevenueQuartile
ORDER BY RevenueQuartile;

/*
FINDINGS:
1. The analysis covered 4,336 customers, divided equally into four revenue quartiles.
2. The top 25% generated £6,819,391.46 in revenue.
3. The top quartile contributed approximately 78.8% of total customer revenue.
4. Top-quartile customers averaged 10 orders.
5. Bottom-quartile customers averaged £176.07 in revenue and 1 order.

ACTIONS:
1. Segmented customers using NTILE(4), ranked by revenue.
2. Compared customer counts, average revenue, order frequency and segment revenue.
3. Identified the top quartile as the primary customer revenue segment.
4. No data modifications required.
*/



-- 4.4.3 Customer Order Frequency Analysis

WITH CustomerOrders AS 
(
SELECT 
	CustomerID,
	COUNT (DISTINCT InvoiceNo) AS TotalOrders,
	SUM (Quantity * UnitPrice) AS SalesRevenue
FROM dbo.online_retail_clean
WHERE CustomerID IS NOT NULL AND InvoiceNo NOT LIKE 'C%' AND InvoiceNo NOT LIKE 'A%' AND StockCode NOT IN ('DOT','POST','M')
GROUP BY CustomerID
),

CustomerOrderFrequency AS 
(
SELECT 
	CASE WHEN TotalOrders = 1 THEN '1 Order'
		 WHEN TotalOrders BETWEEN 2 AND 5 THEN '2 - 5 Orders'
		 WHEN TotalOrders BETWEEN 6 AND 10 THEN '6 - 10 Orders'
		 ELSE 'More Than 10 Orders'
	END AS OrderSegments,
	COUNT (*) AS TotalCustomers,
	SUM (TotalOrders) AS TotalOrders,
	SUM (SalesRevenue) AS TotalRevenue
FROM CustomerOrders
GROUP BY 
	CASE WHEN TotalOrders = 1 THEN '1 Order'
		 WHEN TotalOrders BETWEEN 2 AND 5 THEN '2 - 5 Orders'
		 WHEN TotalOrders BETWEEN 6 AND 10 THEN '6 - 10 Orders'
		 ELSE 'More Than 10 Orders'
	END
)

SELECT 
	OrderSegments,
	TotalCustomers,
	TotalOrders,
	CAST (TotalRevenue AS decimal (18,2)) AS TotalRevenue_GBP,
	CAST (TotalCustomers * 100.0 / SUM (TotalCustomers) OVER () AS DECIMAL (18,2)) AS CustomerPercentage
FROM CustomerOrderFrequency
ORDER BY OrderSegments;


/*
FINDINGS:
1. Analyzed 4,336 identified customers.
2. 1,506 customers (34.73%) placed only one order.
3. The 2-5 order group was the largest segment, with 1,965 customers.
4. Customers placing more than 10 orders represented 7.66% of customers.
5. This high-frequency group generated £4,295,137.11,
   approximately 49.1% of total customer revenue.
6. Repeat customers generated approximately 90.3% of total revenue.

ACTIONS:
1. Grouped customers by total completed orders.
2. Compared customer counts, order volumes and revenue.
3. Identified customer retention and repeat-purchase opportunities.
4. No data modifications required.
*/


-- 4.4.4 Customer Revenue Contribution Analysis

WITH CustomerSales AS 
(
SELECT 
	CustomerID,
	SUM (Quantity * UnitPrice) AS TotalRevenue
FROM dbo.online_retail_clean
WHERE CustomerID IS NOT NULL AND InvoiceNo NOT LIKE 'C%' AND InvoiceNo NOT LIKE 'A%' AND StockCode NOT IN ('DOT','POST','M')
GROUP BY CustomerID
),

OverralTotalSales AS 
(
SELECT 
	CustomerID,
	TotalRevenue,
	SUM (TotalRevenue) OVER () AS TotalRevenue_GBP
FROM CustomerSales 
)

SELECT 
	CustomerID,
	TotalRevenue,
	TotalRevenue_GBP,
	CAST (TotalRevenue * 100.0 / NULLIF (TotalRevenue_GBP,0) AS DECIMAL (18,2))AS PercentageContribution
FROM OverralTotalSales
ORDER BY TotalRevenue DESC;


/*
FINDINGS:
1. Identified customer revenue totaled £8,744,078.64.
2. The analysis covered 4,336 customers.
3. Customer 14646 contributed the highest share at 3.19%.
4. The top three customers contributed approximately 8.38%.
5. No individual customer contributed more than 4% of revenue.

ACTIONS:
1. Calculated individual customer revenue.
2. Calculated each customer's percentage contribution to total revenue.
3. Ranked customers by revenue in descending order.
4. No data modifications required.
*/



           -- 4.5 GEOGRAPHICAL PERFORMANCE ANALYSIS
-----------------------------------------------------------------------------------

SELECT 
	Country,
	COUNT (DISTINCT CustomerID) AS TotalCustomer,
	COUNT (DISTINCT InvoiceNo) AS TotalOrders,
	SUM (Quantity) AS NetQuantitySold, 
	SUM (UnitPrice * Quantity) AS TotalRevenue
FROM dbo.online_retail_clean
WHERE CustomerID IS NOT NULL AND InvoiceNo NOT LIKE 'C%' AND InvoiceNo NOT LIKE 'A%' AND StockCode NOT IN ('DOT','POST','M')
GROUP BY Country
ORDER BY TotalRevenue DESC;


/*
FINDINGS:
1. The analysis covered sales performance across 37 countries.
2. The United Kingdom was the leading market across all four
   metrics: revenue, customers, orders and net quantity sold.
3. The Netherlands ranked second in revenue and net quantity sold.
4. Ireland ranked third in revenue and net quantity sold.
5. Germany and France also demonstrated significant revenue
   contributions.
6. The UK market accounts for a substantially larger share
   of business activity than other countries.

BUSINESS INSIGHTS:
1. Prioritize customer retention and continued growth in the UK.
2. Explore opportunities to expand sales in other European markets.
3. Use country-level performance to guide international sales
   and marketing strategies.
*/



            -- 4.6   TIME-BASED SALES ANALYSIS
-----------------------------------------------------------------------------------------
-- 4.6.1 Revenue and Order Performance by Day of the Week

SET DATEFIRST 1;

SELECT
	DATENAME (WEEKDAY,InvoiceDate) AS Day_Of_Week,
	COUNT (DISTINCT InvoiceNo) AS TotalOrders,
	SUM (Quantity) AS NetQuantitySold,
	CAST (SUM (Quantity * UnitPrice) AS DECIMAL (18,2))AS TotalRevenue_GBP
FROM dbo.online_retail_clean
WHERE CustomerID IS NOT NULL AND InvoiceNo NOT LIKE 'C%' AND InvoiceNo NOT LIKE 'A%' AND StockCode NOT IN ('DOT','POST','M')
GROUP BY DATEPART (WEEKDAY,InvoiceDate),DATENAME (WEEKDAY,InvoiceDate)
ORDER BY
	DATEPART (WEEKDAY,InvoiceDate);


/*
FINDINGS:
1. Thursday recorded the highest revenue of £1,941,119.91,
   with 4,006 orders and 1,148,374 units sold.

2. Sunday recorded the lowest revenue of £780,238.80,
   with 2,168 orders and 460,531 units sold.

3. Tuesday generated the second-highest revenue of
   £1,673,648.12.

4. Saturday had no records matching the applied filters.

ACTIONS:
1. Investigate factors contributing to stronger Thursday
   sales performance.

2. Review Sunday sales performance to identify opportunities
   to improve revenue and customer activity.

3. Consider weekday sales patterns when planning inventory
   and promotional activities.
*/




-- 4.6.2 Daily Revenue Performance

SELECT
    CAST(InvoiceDate AS DATE) AS SalesDate,
    COUNT(DISTINCT InvoiceNo) AS TotalOrders,
    SUM(Quantity) AS NetQuantitySold,
    CAST(SUM(Quantity * UnitPrice) AS DECIMAL(18,2)) AS TotalRevenue_GBP
FROM dbo.online_retail_clean
WHERE CustomerID IS NOT NULL AND InvoiceNo NOT LIKE 'C%' AND InvoiceNo NOT LIKE 'A%' AND StockCode NOT IN ('DOT','POST','M')
GROUP BY CAST(InvoiceDate AS DATE)
ORDER BY TotalRevenue_GBP DESC;


/*
FINDINGS:
1. December 9, 2011 recorded the highest daily revenue
   of £184,170.66, generated from 41 orders.

2. September 20, 2011 ranked second with revenue
   of £103,280.30 from 67 orders.

3. January 18, 2011 ranked third with revenue
   of £87,130.81 from 32 orders.

4. The highest-revenue day did not have the highest
   order count, indicating differences in average
   transaction value across sales dates.

ACTIONS:
1. Investigate the unusually high revenue recorded
   on December 9, 2011.

2. Monitor daily revenue and order activity to identify
   unusually strong sales periods.
*/


-- 4.6.3 Sales Performance by Calendar Day

SELECT
    DAY(InvoiceDate) AS DayOfMonth,
    COUNT(DISTINCT InvoiceNo) AS TotalOrders,
    SUM(Quantity) AS NetQuantitySold,
    CAST(SUM(Quantity * UnitPrice) AS DECIMAL(18,2)) AS TotalRevenue_GBP
FROM dbo.online_retail_clean
WHERE CustomerID IS NOT NULL AND InvoiceNo NOT LIKE 'C%' AND InvoiceNo NOT LIKE 'A%' AND StockCode NOT IN ('DOT','POST','M')
GROUP BY DAY(InvoiceDate)
ORDER BY TotalRevenue_GBP DESC;


/*
FINDINGS:
1. The 9th recorded the highest combined revenue
   of £456,605.13.

2. The 7th ranked second with revenue of £373,247.30.

3. The 18th recorded the highest net quantity sold
   among the visible results, with 249,820 units.

4. The 7th recorded the highest order count among
   the visible results, with 770 orders.

5. Revenue, order volume and quantity sold do not
   necessarily peak on the same calendar day.

ACTIONS:
1. Investigate sales activity around the 9th to
   understand the factors behind its strong revenue.

2. Consider calendar-day patterns when planning
   promotional campaigns and inventory.
*/




              -- 4.7 CANCELLATION AND ADJUSTMENT ANALYSIS
-------------------------------------------------------------------------------------

-- 4.7.1 Top 10 Products by Cancellation Value

SELECT TOP 10
	StockCode,
	Description,
	COUNT (DISTINCT InvoiceNo) AS CancellationOrders,
	SUM (ABS (Quantity)) AS QuantityCancelled,
	CAST (SUM (ABS (Quantity * UnitPrice)) AS decimal (18,2)) AS CancelledValue
FROM dbo.online_retail_clean
WHERE InvoiceNo LIKE 'C%' AND StockCode NOT IN ('POST','DOT','M')
GROUP BY StockCode,Description
ORDER BY CancelledValue DESC;


/*
FINDINGS:
1. Paper Craft, Little Birdie recorded the highest visible
   cancellation value of £168,469.60 from one cancellation invoice.

2. Medium Ceramic Top Storage Jar recorded £77,479.64
   across 10 cancellation invoices.

3. Regency Cakestand recorded 180 cancellation invoices,
   the highest count among the visible results.

4. Amazon Fee recorded cancellation value of £23,528.59.

5. Paper Craft, Little Birdie had an unusually high
   cancellation quantity of 80,995, requiring investigation.

ACTIONS:
1. Investigate the unusually high cancellation quantity
   recorded for Paper Craft, Little Birdie.

2. Review products with high cancellation values and
   frequent cancellation invoices.

3. Distinguish merchandise cancellations from cancelled
   fees and other non-merchandise entries.
*/


-- 4.7.2 Cancellation Rate by Product

WITH ProductCancellation AS
(
    SELECT
        StockCode,
        Description,

        SUM(
            CASE
                WHEN InvoiceNo NOT LIKE 'C%'
                 AND InvoiceNo NOT LIKE 'A%'
                 AND Quantity > 0
                THEN Quantity
                ELSE 0
            END
        ) AS QuantitySold,

        SUM(
            CASE
                WHEN InvoiceNo LIKE 'C%'
                THEN ABS(Quantity)
                ELSE 0
            END
        ) AS QuantityCancelled

    FROM dbo.online_retail_clean
    WHERE StockCode NOT IN ('DOT', 'POST', 'M')
    GROUP BY
        StockCode,
        Description
)

SELECT
    StockCode,
    Description,
    QuantitySold,
    QuantityCancelled,

    CAST(
        QuantityCancelled * 100.0 /
        NULLIF(QuantitySold + QuantityCancelled, 0)
        AS DECIMAL(10,2)
    ) AS CancellationRate_Percent

FROM ProductCancellation
WHERE QuantitySold > 0
  AND QuantityCancelled > 0
ORDER BY CancellationRate_Percent DESC;


/*
FINDINGS:
1. Samples recorded the highest cancellation rate of
   96.77%, with 60 cancelled units and 2 sold units.

2. Amazon Fee recorded a cancellation rate of 94.12%.

3. Several physical products recorded cancellation rates
   exceeding 50%.

4. Paper Craft, Little Birdie recorded 80,995 sold units
   and 80,995 cancelled units, representing a 50% rate.

5. High cancellation percentages do not always indicate
   high cancellation volumes or financial impact.

ACTIONS:
1. Investigate products with unusually high cancellation rates.

2. Prioritize products with both high cancellation rates
   and significant cancellation quantities.

3. Separate physical merchandise from transaction charges
   when interpreting product cancellation performance.
*/


-- 4.7.3 Overall Sales vs. Cancellation Performance

SELECT
    COUNT(DISTINCT CASE
        WHEN InvoiceNo NOT LIKE 'C%'
         AND InvoiceNo NOT LIKE 'A%'
        THEN InvoiceNo
    END) AS TotalSalesOrders,

    COUNT(DISTINCT CASE
        WHEN InvoiceNo LIKE 'C%'
        THEN InvoiceNo
    END) AS TotalCancellationOrders,

    SUM(CASE
        WHEN InvoiceNo NOT LIKE 'C%'
         AND InvoiceNo NOT LIKE 'A%'
         AND Quantity > 0
        THEN Quantity
        ELSE 0
    END) AS TotalQuantitySold,

    SUM(CASE
        WHEN InvoiceNo LIKE 'C%'
        THEN ABS(Quantity)
        ELSE 0
    END) AS TotalQuantityCancelled,

    CAST(SUM(CASE
        WHEN InvoiceNo NOT LIKE 'C%'
         AND InvoiceNo NOT LIKE 'A%'
         AND Quantity > 0
        THEN Quantity * UnitPrice
        ELSE 0
    END) AS DECIMAL(18,2)) AS TotalSalesValue_GBP,

    CAST(SUM(CASE
        WHEN InvoiceNo LIKE 'C%'
        THEN ABS(Quantity * UnitPrice)
        ELSE 0
    END) AS DECIMAL(18,2)) AS TotalCancellationValue_GBP,

    CAST(
        SUM(CASE
            WHEN InvoiceNo LIKE 'C%'
            THEN ABS(Quantity)
            ELSE 0
        END) * 100.0 /
        NULLIF(
            SUM(CASE
                WHEN InvoiceNo NOT LIKE 'C%'
                 AND InvoiceNo NOT LIKE 'A%'
                 AND Quantity > 0
                THEN Quantity
                ELSE 0
            END)
            +
            SUM(CASE
                WHEN InvoiceNo LIKE 'C%'
                THEN ABS(Quantity)
                ELSE 0
            END), 0
        )
        AS DECIMAL(10,2)
    ) AS QuantityCancellationRate_Percent,

    CAST(
        SUM(CASE
            WHEN InvoiceNo LIKE 'C%'
            THEN ABS(Quantity * UnitPrice)
            ELSE 0
        END) * 100.0 /
        NULLIF(
            SUM(CASE
                WHEN InvoiceNo NOT LIKE 'C%'
                 AND InvoiceNo NOT LIKE 'A%'
                 AND Quantity > 0
                THEN Quantity * UnitPrice
                ELSE 0
            END)
            +
            SUM(CASE
                WHEN InvoiceNo LIKE 'C%'
                THEN ABS(Quantity * UnitPrice)
                ELSE 0
            END), 0
        )
        AS DECIMAL(10,2)
    ) AS ValueCancellationRate_Percent

FROM dbo.online_retail_clean
WHERE StockCode NOT IN ('DOT', 'POST', 'M');


/*
FINDINGS:
1. Regular sales recorded 21,896 distinct orders,
   compared with 3,577 cancellation orders.

2. Total quantity sold was 5,629,817 units,
   while cancelled quantity was 271,346 units.

3. The quantity cancellation rate was 4.60%.

4. Regular sales value amounted to £10,268,945.27,
   while cancellation value was £735,320.74.

5. The value cancellation rate was 6.68%, higher
   than the quantity cancellation rate of 4.60%.

ACTIONS:
1. Monitor cancellation rates to identify changes
   in cancellation activity.

2. Investigate products contributing significantly
   to cancellation value and quantity.

3. Review cancellation patterns to identify possible
   improvements in order processing and fulfillment.
*/