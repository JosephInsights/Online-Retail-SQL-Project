
/*
========================================================
PROJECT: E-Commerce Sales, Customer Behaviour & Revenue Analysis
DATABASE: OnlineRetailAnalytics
TOOL: SQL Server
AUTHOR: Joseph Njoroge Ng'endo

SCRIPT NAME: 02_Data_Quality_Assessment.sql

PROJECT PHASE: Phase 2 - Data Quality Assessment

DESCRIPTION:
Assess the quality, completeness, consistency and
reliability of the original Online Retail dataset.
================================================================================
*/

     -- 2.1) INSPECTION OF THE ORIGINAL TABLE STRUCTURE AND DATATYPES

SELECT 
	COLUMN_NAME,
	DATA_TYPE,
	IS_NULLABLE,
	NUMERIC_PRECISION,
	NUMERIC_SCALE,
	CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
		AND TABLE_NAME = 'online_retail_raw';

-- FINDINGS:
-- 1. Dataset contains 8 columns.
-- 2. InvoiceNo, StockCode, Description and Country
--    were imported as NVARCHAR(255).
-- 3. Quantity and UnitPrice were imported as FLOAT.
-- 4. InvoiceDate was imported as DATETIME.
-- 5. CustomerID was imported as INT.
-- 6. All columns allow NULL values.

-- ACTION:
-- No changes made during this assessment.
-- Data types will be reviewed during the data cleaning phase.


     -- 2.2 MISSING AND BLANK VALUES ASSESSMENT

SELECT 
	COUNT (*) AS TotalRecords,
	SUM (CASE WHEN InvoiceNo IS NULL THEN 1 ELSE 0 END) AS MissingInvoiceNo,
	SUM (CASE WHEN StockCode IS NULL OR TRIM (StockCode) = '' THEN 1 ELSE 0 END) AS MissingStockCode,
	SUM (CASE WHEN Description IS NULL OR TRIM (Description) = '' THEN 1 ELSE 0 END ) AS MissingDescription,
	SUM (CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END ) AS MissingQuantity,
	SUM (CASE WHEN InvoiceDate IS NULL  THEN 1 ELSE 0 END ) AS MissingInvoiceDate,
	SUM (CASE WHEN UnitPrice IS NULL  THEN 1 ELSE 0 END ) AS MissingUnitPrice,
	SUM (CASE WHEN CustomerID IS NULL  THEN 1 ELSE 0 END ) AS MissingCustomerID,
	SUM (CASE WHEN Country IS NULL OR TRIM (Country) = '' THEN 1 ELSE 0 END ) AS MissingCountry
FROM dbo.online_retail_raw;

          
          -- 2.2.1) Separating NULL and blank string values in the StockCode column 

SELECT 
	COUNT (*) AS TotalRecords,
	SUM (CASE WHEN Description IS NULL THEN 1 ELSE 0 END ) AS MissingDescriptionNulls,
	SUM (CASE WHEN TRIM (Description) = '' THEN 1 ELSE 0 END ) AS MissingDiscriptionBlanks
FROM dbo.online_retail_raw;

/*
FINDINGS:

1. Total dataset records: 541,909.
2. InvoiceNo has 0 NULL values.
3. StockCode has 0 NULL or blank values.
4. Description has 1,454 NULL values and 0 blank values.
5. CustomerID has 135,080 NULL values.
6. Quantity, InvoiceDate and UnitPrice have 0 NULL values.
7. Country has 0 NULL or blank values.

ACTIONS:

1. No records deleted or modified.
2. Missing CustomerID values retained for further analysis.
3. Missing Description values flagged for further assessment.
4. No missing InvoiceNo values identified.

*/


	-- 2.3 DUPLICATE CHECK ACCROSS THE DATASET
       
           -- 2.3.1 Identify Duplicate Records

WITH DuplicateCheck AS 
(
SELECT 
	InvoiceNo,
	StockCode,
	Description,
	Quantity,
	InvoiceDate,
	UnitPrice,
	CustomerID,
	Country,
	ROW_NUMBER () OVER (PARTITION BY InvoiceNo,StockCode,Description,Quantity,InvoiceDate,UnitPrice,
						CustomerID,Country ORDER BY InvoiceNo) AS RowNum
FROM dbo.online_retail_raw
)
SELECT *
FROM DuplicateCheck
WHERE RowNum > 1;

-- FINDINGS:
-- 5,268 additional duplicate occurrences identified.
-- Records with RowNum > 1 represent additional copies.

-- ACTIONS:
-- No records deleted.
-- Duplicate occurrences flagged for further assessment.

          
          
          -- 2.3.2 Duplicate Occurrences Summary

WITH DuplicateCheck AS (
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY
                InvoiceNo,
                StockCode,
                Description,
                Quantity,
                InvoiceDate,
                UnitPrice,
                CustomerID,
                Country
            ORDER BY InvoiceNo
        ) AS RowNum
    FROM dbo.online_retail_raw
)
SELECT
    COUNT(*) AS TotalDuplicateOccurrences,
    COUNT(DISTINCT RowNum) AS DuplicateRowNumberLevels
FROM DuplicateCheck
WHERE RowNum > 1;

-- FINDINGS:
-- Total additional duplicate occurrences: 5,268.
-- Distinct row-number levels: 19.

-- ACTIONS:
-- Established the overall volume of additional
-- duplicate occurrences for documentation.
-- No records deleted.


            -- 2.3.3 Identify Distinct Duplicate Groups 

WITH DuplicateGroups AS (
    SELECT
        InvoiceNo,
        StockCode,
        Description,
        Quantity,
        InvoiceDate,
        UnitPrice,
        CustomerID,
        Country
    FROM dbo.online_retail_raw
    GROUP BY
        InvoiceNo,
        StockCode,
        Description,
        Quantity,
        InvoiceDate,
        UnitPrice,
        CustomerID,
        Country
    HAVING COUNT(*) > 1
)
SELECT COUNT(*) AS TotalDuplicateGroups
FROM DuplicateGroups

-- FINDINGS:
-- Total distinct duplicate groups: 4,879.

-- ACTIONS:
-- Established the number of unique combinations
-- containing repeated records.
-- No records deleted.


         -- 2.3.4 Highest Frequency Duplicate Assessment

SELECT TOP 10
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country,
    COUNT(*) AS DuplicateCount
FROM dbo.online_retail_raw
GROUP BY
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC;

-- FINDINGS:
-- Highest duplicate frequency: 20 occurrences.
-- InvoiceNo: 555524.
-- StockCode: 22698.
-- Description: PINK REGENCY TEACUP AND SAUCER.

-- ACTIONS:
-- Flagged highly repeated records for evaluation.
-- No records deleted.


     
      -- 2.4 INVALID AND INCONSISTENT VALUES ASSESSMENT

               -- 2.4.1 Numerical Values Assessment

SELECT 
    COUNT (*) AS TotalRecords,
    SUM (CASE WHEN Quantity = 0 THEN 1 ELSE 0 END ) AS ZeroQuantity,
    SUM (CASE WHEN Quantity < 0 THEN 1 ELSE 0 END ) AS NegativeQuantity,
    SUM (CASE WHEN UnitPrice = 0 THEN 1 ELSE 0 END ) AS ZeroUnitPrice,
    SUM (CASE WHEN UnitPrice < 0 THEN 1 ELSE 0 END ) AS NegativeUnitPrice
FROM dbo.online_retail_raw


-- FINDINGS:
-- 1. No records were found with zero quantity.
-- 2. 10,624 records have negative quantities, potentially
--    representing product returns or cancellations.
-- 3. 2,515 records have zero unit prices, potentially
--    representing free or promotional items.
-- 4. Two records have negative unit prices, requiring
--    further investigation.

-- ACTIONS:
-- 1. Flagged negative quantities for further evaluation.
-- 2. Flagged zero unit prices for business interpretation.
-- 3. Flagged negative unit prices for investigation.
-- 4. No records modified or deleted.



             -- 2.4.2 Investigate the negative Unit Prices

SELECT *
FROM dbo.online_retail_raw
WHERE UnitPrice < 0;

-- FINDINGS:
-- 1. Two records contain negative UnitPrice values.
-- 2. Both records have StockCode 'B'.
-- 3. Description is 'Adjust bad debt'.
-- 4. Both records have a UnitPrice of -11062.06.
-- 5. InvoiceNo and CustomerID are NULL.

-- ACTIONS:
-- 1. Identified both records as bad debt adjustments.
-- 2. Classified them as non-standard accounting transactions.
-- 3. Retained both records pending business interpretation.
-- 4. No records modified or deleted.


           -- 2.4.3 Investigate the Negative Quantity Records

SELECT TOP 20 *
FROM dbo.online_retail_raw
WHERE Quantity < 0
ORDER BY Quantity ASC;


-- FINDINGS:
-- 1. Negative quantities include operational adjustments,
--    damaged goods, discarded products and potential returns.
-- 2. Some descriptions explicitly indicate damaged or
--    unsalable products.
-- 3. Several records have NULL InvoiceNo and CustomerID.
-- 4. Some records also have missing descriptions.

-- ACTIONS:
-- 1. Flagged negative quantities for business interpretation.
-- 2. Identified operational adjustments and potential returns.
-- 3. Retained all records pending further assessment.
-- 4. No records modified or deleted.

 
          -- 2.4.4 Establishing how many Negative Quantity records have Missing InvoiceNo

SELECT
    COUNT(*) AS TotalNegativeQuantityRecords,
    SUM(CASE WHEN InvoiceNo IS NULL THEN 1 ELSE 0 END) AS MissingInvoiceNo,
    SUM(CASE WHEN Description IS NULL THEN 1 ELSE 0 END) AS MissingDescription,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS MissingCustomerID
FROM dbo.online_retail_raw
WHERE Quantity < 0;

-- FINDINGS:
-- 1. 10,624 records have negative quantities.
-- 2. None have missing InvoiceNo values.
-- 3. 862 records have missing Description values.
-- 4. 1,719 records have missing CustomerID values.

-- ACTIONS:
-- 1. Negative quantity records flagged for further assessment.
-- 2. Missing descriptions flagged for further assessment.
-- 3. Missing CustomerID records retained for analysis.
-- 4. No records modified or deleted.



            -- 2.4.5 Investigate the Zero Unit Price Records

SELECT TOP 20 *
FROM dbo.online_retail_raw
WHERE UnitPrice = 0
ORDER BY Quantity DESC;

SELECT
    COUNT(*) AS TotalZeroUnitPriceRecords,

    SUM(CASE
        WHEN InvoiceNo IS NULL THEN 1
        ELSE 0
    END) AS MissingInvoiceNo,

    SUM(CASE
        WHEN Description IS NULL THEN 1
        ELSE 0
    END) AS MissingDescription,

    SUM(CASE
        WHEN CustomerID IS NULL THEN 1
        ELSE 0
    END) AS MissingCustomerID,

    SUM(CASE
        WHEN Quantity < 0 THEN 1
        ELSE 0
    END) AS NegativeQuantity

FROM dbo.online_retail_raw
WHERE UnitPrice = 0;

-- FINDINGS:
-- 1. Identified 2,515 records with zero unit prices.
-- 2. 1,454 records have missing product descriptions.
-- 3. 2,475 records have missing CustomerIDs.
-- 4. 1,336 records have negative quantities, potentially
--    representing returns or transaction adjustments.
-- 5. All records have an InvoiceNo value.

-- ACTIONS:
-- 1. Flagged zero unit price records for further investigation.
-- 2. Identified missing product descriptions and customer references.
-- 3. Flagged negative quantity records for business interpretation.
-- 4. Retained all records pending further investigation.
-- 5. No records modified or deleted.


     -- 2.5 DATE AND TEMPORAL CONSISTENCY ASSESSMENT

               -- 2.5.1 InvoiceDate Range and Missing Values Assessment

SELECT
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN InvoiceDate IS NULL THEN 1 ELSE 0 END) AS MissingInvoiceDates,
    MIN(InvoiceDate) AS EarliestInvoiceDate,
    MAX(InvoiceDate) AS LatestInvoiceDate
FROM dbo.online_retail_raw;


-- FINDINGS:
-- 1. All 541,909 records contain InvoiceDate values.
-- 2. No missing InvoiceDate records were identified.
-- 3. Earliest transaction: 2010-12-01 08:26:00.
-- 4. Latest transaction: 2011-12-09 12:50:00.
-- 5. The dataset covers approximately one year of activity.

-- ACTIONS:
-- 1. Confirmed InvoiceDate completeness.
-- 2. Established the transaction date range.
-- 3. No date corrections or record modifications required.


             --2.5.2 Future and Out-of-Range Date Assessment

SELECT
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN InvoiceDate < '2010-12-01' THEN 1 ELSE 0 END) AS DatesBeforeExpectedRange,
    SUM(CASE WHEN InvoiceDate > '2011-12-09 23:59:59' THEN 1
        ELSE 0
    END) AS DatesAfterExpectedRange
FROM dbo.online_retail_raw;


-- FINDINGS:
-- 1. All 541,909 records fall within the expected date range.
-- 2. No dates were identified before 2010-12-01.
-- 3. No dates were identified after 2011-12-09.
-- 4. No out-of-range transaction dates were detected.

-- ACTIONS:
-- 1. Confirmed consistency of transaction dates.
-- 2. Retained all records.
-- 3. No date corrections or record deletions required.


              -- 2.5.3 Repeated Transaction Date-Time Assessment

WITH TimestampFrequency AS
(
    SELECT
        InvoiceDate,
        COUNT(*) AS RecordsAtTimestamp
    FROM dbo.online_retail_raw
    WHERE InvoiceDate IS NOT NULL
    GROUP BY InvoiceDate
)

SELECT
    COUNT(*) AS RepeatedTimestampValues,
    SUM(RecordsAtTimestamp) AS RecordsSharingRepeatedTimestamps,
    MAX(RecordsAtTimestamp) AS MaximumRecordsAtOneTimestamp
FROM TimestampFrequency
WHERE RecordsAtTimestamp > 1;


-- FINDINGS:
-- 1. Identified 19,018 distinct timestamps appearing more than once.
-- 2. A total of 537,667 records share repeated timestamps.
-- 3. The maximum number of records sharing one timestamp is 1,114.
-- 4. Repeated timestamps do not necessarily indicate duplicate transactions.
-- 5. Multiple invoices and product line items can share timestamps.

-- ACTIONS:
-- 1. Flagged repeated timestamps for analytical awareness.
-- 2. Retained all records because timestamp repetition alone
--    does not establish duplication.
-- 3. No records modified or deleted.

     
     
     -- 2.6 CATEGORICAL DATA CONSISTENCY ASSESSMENT

            -- 2.6.1 Country Values and Distribution Assessment

SELECT 
    Country,
    COUNT (*) AS TotalTransaction
FROM dbo.online_retail_raw
GROUP BY Country
ORDER BY TotalTransaction DESC;

-- FINDINGS:
-- 1. Identified 38 distinct country categories.
-- 2. United Kingdom recorded the highest transaction volume
--    with 495,478 records.
-- 3. Germany and France recorded 9,495 and 8,557 records,
--    respectively.
-- 4. EIRE recorded 8,196 transactions.
-- 5. The dataset contains an Unspecified country category,
--    requiring further consideration.
-- 6. Transaction volumes are heavily concentrated in
--    the United Kingdom.

-- ACTIONS:
-- 1. Established the geographical distribution of transactions.
-- 2. Flagged the Unspecified category for further assessment.
-- 3. Retained all country values pending formatting checks.
-- 4. No records modified or deleted.


              -- 2.6.2 Country Value Consistency Assessment

SELECT
    Country,
    COUNT(*) AS TotalRecords
FROM dbo.online_retail_raw
WHERE Country IS NOT NULL
GROUP BY Country
ORDER BY Country;


/*
FINDINGS:
1. The Country column contains 38 distinct values.
2. Most country names are consistently represented.
3. EIRE (8,196 records) and RSA (58 records)
   use alternative or abbreviated country names.
4. USA (291 records) uses an abbreviated country name.
5. European Community (61 records) and Channel Islands
   (758 records) represent geographical or political groupings
   rather than individual sovereign countries.
6. Unspecified (446 records) represents unidentified
   geographical information.

ACTIONS:
1. Flagged alternative country names and abbreviations
   for potential standardization.
2. Identified non-country geographical classifications.
3. Flagged Unspecified records for further consideration.
4. Retained all original values pending the data
   standardization phase.
5. No records modified or deleted.
*/


                -- 2.6.3 – Product Description and StockCode Categorical Consistency Assessment

SELECT
    StockCode,
    COUNT(DISTINCT Description) AS DistinctDescriptions,
    COUNT(*) AS TotalRecords
FROM dbo.online_retail_raw
WHERE StockCode IS NOT NULL
GROUP BY StockCode
HAVING COUNT(DISTINCT Description) > 1
ORDER BY DistinctDescriptions DESC, TotalRecords DESC;



/*
FINDINGS:
1. A total of 644 StockCodes were identified with more
   than one distinct product description.

2. StockCode 23084 recorded 7 distinct descriptions
   across 1,067 transactions.

3. StockCode 20713 recorded 7 distinct descriptions
   across 684 transactions.

4. StockCode 85175 recorded 6 distinct descriptions
   across 154 transactions.

5. Other StockCodes also showed multiple product
   descriptions, indicating potential inconsistencies
   in product identification and catalogue records.

ACTIONS:
1. Flagged StockCodes associated with multiple
   product descriptions for further investigation.

2. Identified frequently occurring StockCodes with
   multiple descriptions for closer examination.

3. Retained the original StockCodes and product
   descriptions pending verification.

4. No records modified or deleted.

*/

               -- 2.6.3.1 Investigate Multiple Descriptions per StockCode

SELECT
    StockCode,
    Description,
    COUNT(*) AS TotalRecords
FROM dbo.online_retail_raw
WHERE StockCode = '23084'
GROUP BY
    StockCode,
    Description
ORDER BY TotalRecords DESC;

/*
FINDINGS – STOCKCODE 23084

1. StockCode 23084 appears in 1,051 records.

2. The main product description is RABBIT NIGHT LIGHT,
   accounting for 1,051 records.

3. Ten records have NULL product descriptions.

4. Six additional descriptions occur once each and contain
   operational references rather than standard product names.

5. The results indicate that operational notes and missing
   descriptions have been stored in the Description column.

ACTIONS:
1. Identified RABBIT NIGHT LIGHT as the dominant product
   description associated with StockCode 23084.

2. Flagged operational descriptions for further assessment.

3. Flagged the 10 records with missing descriptions.

4. Retained all original records and descriptions.

5. No records modified or deleted.

*/


     -- 2.7 STRUCTURAL AND REFERENTIAL INTEGRITY ASSESSMENT 

               -- 2.7.1 Invoice and Transaction Consistency Assessment

SELECT
    InvoiceNo,
    COUNT(DISTINCT InvoiceDate) AS DistinctInvoiceDates,
    COUNT(*) AS TotalRecords
FROM dbo.online_retail_raw
WHERE InvoiceNo IS NOT NULL
GROUP BY InvoiceNo
HAVING COUNT(DISTINCT InvoiceDate) > 1
ORDER BY DistinctInvoiceDates DESC, TotalRecords DESC;


/*
FINDINGS:
1. Identified 43 InvoiceNos associated with multiple
   transaction timestamps.
2. Each identified invoice has 2 distinct InvoiceDate values.
3. InvoiceNo 574076 has 416 records across 2 timestamps.
4. InvoiceNo 567183 has 399 records across 2 timestamps.
5. These variations indicate potential invoice-level
   timestamp inconsistencies.

ACTIONS:
1. Flagged the 43 invoices for further evaluation.
2. Retained all original invoice timestamps.
3. Deferred any corrections to the data cleaning phase.
4. No records modified or deleted.
*/


                -- 2.7.1.1 Investigate Multiple Timestamps for InvoiceNo 574076

SELECT
    InvoiceNo,
    InvoiceDate,
    COUNT(*) AS TotalRecords
FROM dbo.online_retail_raw
WHERE InvoiceNo = '574076'
GROUP BY InvoiceNo, InvoiceDate
ORDER BY InvoiceDate;

/*
FINDINGS:
1. InvoiceNo 574076 contains 416 records across 2 timestamps.
2. One record was recorded at 15:37.
3. The remaining 415 records were recorded at 15:38.
4. The timestamps differ by only one minute.

ACTIONS:
1. Flagged the invoice for further evaluation.
2. Retained both original timestamps.
3. No timestamp corrections were applied.
4. No records modified or deleted.
*/


        -- 2.7.2 Customer and Invoice Consistency Assessment.

                      -- 2.7.2.1 Identify Invoices Associated with Multiple Customers

SELECT 
    InvoiceNo,
    COUNT (DISTINCT CustomerID) AS TotalCustomer
FROM dbo.online_retail_raw
WHERE InvoiceNo IS NOT NULL AND CustomerID IS NOT NULL
GROUP BY InvoiceNo
HAVING COUNT (DISTINCT CustomerID) > 1;


/*
FINDINGS:
1. No invoices were associated with multiple distinct CustomerIDs.
2. No multiple-customer invoice inconsistencies were detected.

ACTIONS:
1. Confirmed customer consistency across invoice records.
2. No further investigation required for this check.
3. No records modified or deleted.
*/

            
            -- 2.7.2.2 Assess Missing CustomerIDs Across Invoices

SELECT
    COUNT(*) AS TotalRecords,
    COUNT(DISTINCT InvoiceNo) AS DistinctInvoices,
    SUM(CASE
        WHEN CustomerID IS NULL THEN 1
        ELSE 0
    END) AS MissingCustomerIDRecords
FROM dbo.online_retail_raw
WHERE InvoiceNo IS NOT NULL;

/*
FINDINGS:
1. All 541,909 records have an InvoiceNo.
2. The dataset contains 25,900 distinct invoices.
3. 135,080 records have missing CustomerID values.
4. Missing CustomerIDs represent approximately 24.93%
   of the dataset.
5. Missing customer information may affect customer-level
   analysis and reporting.

ACTIONS:
1. Flagged records with missing CustomerIDs for further assessment.
2. Retained records without CustomerIDs.
3. No customer IDs were fabricated or assigned.
4. No records modified or deleted.
*/


           -- 2.7.2.3-- Identify Invoices Affected by Missing CustomerIDs

WITH InvoiceCustomerCheck AS
(
    SELECT
        InvoiceNo,
        COUNT(*) AS TotalRecords,
        SUM(CASE
            WHEN CustomerID IS NULL THEN 1
            ELSE 0
        END) AS MissingCustomerRecords,
        COUNT(DISTINCT CustomerID) AS KnownCustomers
    FROM dbo.online_retail_raw
    WHERE InvoiceNo IS NOT NULL
    GROUP BY InvoiceNo
)

SELECT
    COUNT(*) AS TotalAffectedInvoices,
    SUM(CASE
        WHEN MissingCustomerRecords = TotalRecords THEN 1
        ELSE 0
    END) AS InvoicesWithAllCustomerIDsMissing,
    SUM(CASE
        WHEN MissingCustomerRecords < TotalRecords THEN 1
        ELSE 0
    END) AS InvoicesWithPartiallyMissingCustomerIDs
FROM InvoiceCustomerCheck
WHERE MissingCustomerRecords > 0;


/*
FINDINGS:
1. Identified 3,710 invoices affected by missing CustomerIDs.
2. All 3,710 invoices have CustomerIDs missing across all
   associated records.
3. No invoices have partially missing CustomerIDs.
4. Approximately 14.33% of the 25,900 invoices are affected.

ACTIONS:
1. Flagged affected invoices for data cleaning.
2. Retained all original records.
3. No CustomerIDs were fabricated or assigned.
4. No records modified or deleted.
*/


               
               -- 2.7.3 Transaction Type and Invoice Classification

SELECT 
    CASE WHEN InvoiceNo LIKE 'C%' THEN 'Cancellation'
         WHEN InvoiceNo LIKE 'A%' THEN 'Adjusted'
         ELSE 'Regular'
    END AS Transaction_type,
    COUNT (DISTINCT InvoiceNo) AS DistictInvoiceNo,
    COUNT (*) AS TotalInvoices
FROM dbo.online_retail_raw
GROUP BY 
    CASE WHEN InvoiceNo LIKE 'C%' THEN 'Cancellation'
         WHEN InvoiceNo LIKE 'A%' THEN 'Adjusted'
         ELSE 'Regular'
    END
ORDER BY Transaction_type DESC;


    /*
FINDINGS:
1. Identified 22,061 regular invoices across 532,618 records.
2. Identified 3,836 cancellation invoices across 9,288 records.
3. Identified 3 adjustment invoices across 3 records.
4. The dataset contains 25,900 distinct invoices and 541,909 records.

ACTIONS:
1. Classified invoices using their prefixes.
2. Flagged cancellation and adjustment transactions for appropriate
   treatment during business analysis.
3. Retained all records.
4. No records modified or deleted.
*/



             -- 2.8 Final Data Quality Validation

SELECT
    COUNT(*) AS TotalRecords,
    COUNT(DISTINCT InvoiceNo) AS DistinctInvoices,

    SUM(CASE
        WHEN InvoiceNo IS NULL OR LTRIM(RTRIM(InvoiceNo)) = ''
        THEN 1 ELSE 0
    END) AS MissingInvoiceNumbers,

    SUM(CASE
        WHEN InvoiceNo LIKE 'C%' THEN 1 ELSE 0
    END) AS CancellationRecords,

    SUM(CASE
        WHEN InvoiceNo LIKE 'A%' THEN 1 ELSE 0
    END) AS AdjustmentRecords,

    SUM(CASE
        WHEN InvoiceNo NOT LIKE 'C%'
         AND InvoiceNo NOT LIKE 'A%'
        THEN 1 ELSE 0
    END) AS RegularRecords,

    SUM(CASE
        WHEN CustomerID IS NULL THEN 1 ELSE 0
    END) AS MissingCustomerIDs,

    SUM(CASE
        WHEN Description IS NULL THEN 1 ELSE 0
    END) AS MissingDescriptions

FROM dbo.online_retail_raw;



/*
============================================================
FINAL FINDINGS – PHASE 2 DATA QUALITY ASSESSMENT
============================================================

1. Total dataset records: 541,909.
2. Total distinct invoice numbers: 25,900.
3. No missing or blank invoice numbers identified.
4. Regular transaction records: 532,618.
5. Cancellation transaction records: 9,288.
6. Adjustment transaction records: 3.
7. Missing CustomerID values: 135,080.
8. Missing Description values: 1,454.

============================================================
ACTIONS TAKEN
============================================================

1. Completed the data quality assessment of the dataset.
2. Identified and documented missing values, duplicates,
   unusual numerical values and categorical inconsistencies.
3. Identified cancellation and adjustment transactions
   for appropriate treatment during analysis.
4. Retained records with missing values and unusual
   numerical values for further evaluation during cleaning.
5. No records were intentionally deleted or modified
   during the assessment.

============================================================
PHASE 2 STATUS: COMPLETED
============================================================

The dataset is ready to proceed to Phase 3:
DATA CLEANING AND TRANSFORMATION.

============================================================
*/

















