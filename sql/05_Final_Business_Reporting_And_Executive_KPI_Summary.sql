
/*
================================================================================
PROJECT: ONLINE RETAIL SALES ANALYSIS
PHASE 5: FINAL BUSINESS REPORTING AND EXECUTIVE KPI SUMMARY
================================================================================

DATABASE: OnlineRetailAnalytics
SOURCE TABLE: dbo.online_retail_clean
SQL ENVIRONMENT: Microsoft SQL Server
CURRENCY: GBP (£)

--------------------------------------------------------------------------------
PHASE OBJECTIVE
--------------------------------------------------------------------------------

To consolidate the findings from Phase 4 into business-focused reporting
outputs and executive performance indicators.

This phase focuses on:
    1. Executive sales performance summary.
    2. Key business performance indicators (KPIs).
    3. Sales and cancellation performance reporting.
    4. Consolidated business insights and recommendations.
    5. Preparation of reporting outputs for Power BI visualization.

--------------------------------------------------------------------------------
ANALYTICAL APPROACH
--------------------------------------------------------------------------------

- SQL aggregations and conditional calculations.
- Common Table Expressions (CTEs).
- Window functions where applicable.
- Revenue and cancellation performance metrics.
- Business-focused reporting and interpretation.

--------------------------------------------------------------------------------
IMPORTANT NOTES
--------------------------------------------------------------------------------

- Regular sales invoices exclude InvoiceNo beginning with 'C' or 'A'.
- Cancellation invoices begin with 'C'.
- Adjustment invoices begin with 'A'.
- Financial values are reported in GBP (£).
- Reporting filters will be documented alongside individual queries.

--------------------------------------------------------------------------------
EXPECTED DELIVERABLES
--------------------------------------------------------------------------------

1. Executive KPI summary.
2. Consolidated business performance report.
3. Final business insights and recommendations.
4. Reporting-ready SQL outputs for Power BI.

================================================================================
*/


              -- PHASE 5: FINAL BUSINESS REPORTING
---------------------------------------------------------------------------------

-- 5.1 Executive Business Performance Summary

SELECT
    COUNT(DISTINCT CASE
        WHEN InvoiceNo NOT LIKE 'C%'
         AND InvoiceNo NOT LIKE 'A%'
        THEN InvoiceNo
    END) AS TotalSalesOrders,

    COUNT(DISTINCT CustomerID) AS TotalCustomers,

    SUM(CASE
        WHEN InvoiceNo NOT LIKE 'C%'
         AND InvoiceNo NOT LIKE 'A%'
         AND Quantity > 0
        THEN Quantity
        ELSE 0
    END) AS TotalQuantitySold,

    CAST(SUM(CASE
        WHEN InvoiceNo NOT LIKE 'C%'
         AND InvoiceNo NOT LIKE 'A%'
         AND Quantity > 0
        THEN Quantity * UnitPrice
        ELSE 0
    END) AS DECIMAL(18,2)) AS TotalSalesRevenue_GBP,

    COUNT(DISTINCT CASE
        WHEN InvoiceNo LIKE 'C%'
        THEN InvoiceNo
    END) AS TotalCancellationOrders,

    CAST(SUM(CASE
        WHEN InvoiceNo LIKE 'C%'
        THEN ABS(Quantity * UnitPrice)
        ELSE 0
    END) AS DECIMAL(18,2)) AS TotalCancellationValue_GBP

FROM dbo.online_retail_clean
WHERE StockCode NOT IN ('DOT', 'POST', 'M');



/*
FINDINGS:
1. The business recorded 21,896 regular sales orders.

2. A total of 4,363 distinct customers were identified
   across the filtered transaction records.

3. Total quantity sold amounted to 5,629,817 units.

4. Total regular sales revenue was £10,268,945.27.

5. The business recorded 3,577 cancellation orders.

6. The total cancellation value amounted to £735,320.74.

7. Cancellation activity represents an important area
   for monitoring alongside overall sales performance.

ACTIONS:
1. Monitor sales revenue, order volume and customer
   activity to evaluate overall business performance.

2. Investigate cancellation activity to identify
   products and processes requiring improvement.

3. Use the executive KPIs to support management
   reporting and business decision-making.

IMPORTANT NOTES:
- StockCodes DOT, POST and M were excluded.
- StockCode B was retained because it is a valid
  stock code in this analysis.
- Customer count includes distinct customers across
  the filtered transaction records, not only regular
  sales invoices.
- Cancellation value is not necessarily a confirmed
  financial loss.
- All financial values are reported in GBP (£).
*/




-- 5.2 Sales Efficiency and Customer Value KPIs

WITH InvoiceSummary AS
(
    SELECT
        InvoiceNo,
        CustomerID,
        SUM(Quantity) AS OrderQuantity,
        SUM(Quantity * UnitPrice) AS OrderRevenue_GBP
    FROM dbo.online_retail_clean
    WHERE CustomerID IS NOT NULL AND InvoiceNo NOT LIKE 'C%'
      AND InvoiceNo NOT LIKE 'A%'
      AND Quantity > 0
      AND StockCode NOT IN ('DOT', 'POST', 'M')
    GROUP BY
        InvoiceNo,
        CustomerID
)

SELECT
    COUNT(DISTINCT InvoiceNo) AS TotalSalesOrders,

    COUNT(DISTINCT CustomerID) AS TotalCustomers,

    CAST(
        SUM(OrderRevenue_GBP) /
        NULLIF(COUNT(DISTINCT InvoiceNo), 0)
        AS DECIMAL(18,2)
    ) AS AverageOrderValue_GBP,

    CAST(
        SUM(OrderQuantity) * 1.0 /
        NULLIF(COUNT(DISTINCT InvoiceNo), 0)
        AS DECIMAL(18,2)
    ) AS AverageUnitsPerOrder,

    CAST(
        SUM(OrderRevenue_GBP) /
        NULLIF(COUNT(DISTINCT CustomerID), 0)
        AS DECIMAL(18,2)
    ) AS AverageRevenuePerCustomer_GBP

FROM InvoiceSummary;



/*
FINDINGS:
1. The analysis identified 18,419 sales orders from
   4,336 customers.

2. Average Order Value (AOV) was £474.73.

3. Average quantity purchased per order was 279.92 units.

4. Average revenue generated per identified customer
   was £2,016.62.

5. The analysis provides an overview of order value,
   purchasing volume and customer revenue contribution.

ACTIONS:
1. Monitor Average Order Value to identify opportunities
   to increase revenue per transaction.

2. Use customer purchasing patterns to develop
   targeted sales and retention strategies.

3. Monitor average units per order to support
   inventory and fulfillment planning.

IMPORTANT NOTES:
- Cancellation and adjustment invoices were excluded.
- Only positive quantities were included.
- Customers with missing CustomerID were excluded.
- StockCodes DOT, POST and M were excluded.
- StockCode B was retained.
- Financial values are reported in GBP (£).
*/




-- 5.3 Order Value Distribution Analysis

WITH InvoiceSummary AS
(
    SELECT
        InvoiceNo,
        SUM(Quantity * UnitPrice) AS OrderRevenue_GBP
    FROM dbo.online_retail_clean
    WHERE InvoiceNo NOT LIKE 'C%'
      AND InvoiceNo NOT LIKE 'A%'
      AND CustomerID IS NOT NULL
      AND Quantity > 0
      AND StockCode NOT IN ('DOT', 'POST', 'M')
    GROUP BY InvoiceNo
),

OrderSegments AS
(
    SELECT
        InvoiceNo,
        OrderRevenue_GBP,
        NTILE(4) OVER (
            ORDER BY OrderRevenue_GBP DESC
        ) AS RevenueQuartile
    FROM InvoiceSummary
)

SELECT
    CASE RevenueQuartile
        WHEN 1 THEN 'Top 25% - Highest Value Orders'
        WHEN 2 THEN 'Upper Middle 25%'
        WHEN 3 THEN 'Lower Middle 25%'
        WHEN 4 THEN 'Bottom 25% - Lowest Value Orders'
    END AS OrderSegment,

    COUNT(*) AS TotalOrders,

    CAST(AVG(OrderRevenue_GBP) AS DECIMAL(18,2))
        AS AverageOrderValue_GBP,

    CAST(MIN(OrderRevenue_GBP) AS DECIMAL(18,2))
        AS MinimumOrderValue_GBP,

    CAST(MAX(OrderRevenue_GBP) AS DECIMAL(18,2))
        AS MaximumOrderValue_GBP,

    CAST(SUM(OrderRevenue_GBP) AS DECIMAL(18,2))
        AS TotalRevenue_GBP

FROM OrderSegments
GROUP BY RevenueQuartile
ORDER BY RevenueQuartile;



/*
FINDINGS:
1. The top 25% of sales orders generated total revenue
   of £5,619,201.02.

2. The highest-value order segment contributed approximately
   64.25% of total revenue.

3. The bottom 25% of orders generated £417,681.42,
   representing approximately 4.78% of total revenue.

4. Average order value ranged from £90.72 in the bottom
   quartile to £1,220.24 in the top quartile.

5. The highest individual order value was £168,469.60,
   requiring further investigation.

6. Some orders in the bottom quartile had zero revenue
   despite containing positive quantities.

ACTIONS:
1. Prioritize retention and service quality for customers
   associated with high-value orders.

2. Investigate unusually high-value transactions to
   confirm their accuracy.

3. Review zero-revenue transactions to understand why
   positive quantities generated no sales value.

4. Develop strategies to increase the average order
   value of lower-performing order segments.

IMPORTANT NOTES:
- Orders were divided into four revenue quartiles using NTILE(4).
- Cancellation and adjustment invoices were excluded.
- Customers with missing CustomerID were excluded.
- Only positive quantities were included.
- StockCodes DOT, POST and M were excluded.
- StockCode B was retained.
- Financial values are reported in GBP (£).
*/


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


/*
================================================================================
5.4 FINAL EXECUTIVE BUSINESS INSIGHTS AND RECOMMENDATIONS
================================================================================

KEY BUSINESS INSIGHTS:

1. SALES PERFORMANCE
   - Total sales revenue was £10,268,945.27.
   - The analysis identified 21,896 regular sales orders.

2. CUSTOMER PERFORMANCE
   - The identified customer analysis covered 4,336 customers.
   - Average revenue per identified customer was £2,016.62.
   - The top 25% of customers generated approximately
     78.8% of identified customer revenue.

3. ORDER VALUE DISTRIBUTION
   - The top 25% of orders generated £5,619,201.02.
   - This represented approximately 64.25% of revenue
     in the order-value analysis.

4. PRODUCT PERFORMANCE
   - Regency Cakestand 3 Tier was the leading physical
     product by revenue.
   - Unusually high quantities for Paper Craft,
     Little Birdie require further investigation.

5. GEOGRAPHIC PERFORMANCE
   - The United Kingdom was the dominant sales market.
   - Several international markets also demonstrated
     significant sales activity.

6. CANCELLATION PERFORMANCE
   - Quantity cancellation rate was 4.60%.
   - Value cancellation rate was 6.68%.
   - Cancellation value amounted to £735,320.74.

--------------------------------------------------------------------------------
FINAL BUSINESS RECOMMENDATIONS:
--------------------------------------------------------------------------------

1. Strengthen retention strategies for high-value customers.

2. Improve sales opportunities among lower-value customers.

3. Prioritize inventory planning using product sales performance.

4. Investigate unusual transaction quantities and values.

5. Evaluate international markets for growth opportunities.

6. Monitor cancellation rates and improve order processing
   and fulfillment procedures.

--------------------------------------------------------------------------------
PHASE 5 CONCLUSION:
--------------------------------------------------------------------------------

Phase 5 consolidated the analytical findings into executive
performance indicators and actionable business recommendations.

The reporting outputs provide a foundation for management
decision-making and subsequent Power BI visualization.

================================================================================
*/
