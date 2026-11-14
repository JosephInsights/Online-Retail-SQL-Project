/*==============================================================
  PHASE 3: DATA CLEANING AND TRANSFORMATION
  --------------------------------------------------------------
  OBJECTIVE:
  Clean and transform the dataset by addressing the data quality
  issues identified during Phase 2, while preserving data
  integrity and maintaining the original dataset.

  SOURCE TABLE: dbo.online_retail_raw
  WORKING TABLE: dbo.online_retail_clean

  KEY ACTIVITIES:
  1. Create a separate working table.
  2. Handle duplicate records.
  3. Address missing values.
  4. Evaluate unusual numerical values.
  5. Standardise categorical values where appropriate.
  6. Validate data types and transformed records.
  7. Perform final data quality validation.

  IMPORTANT:
  The original dataset will remain unchanged.
==============================================================*/



-- ==============================================================
-- PHASE 3: DATA CLEANING AND TRANSFORMATION
-- ===============================================================


      -- (3.1): CREATE A CLEAN WORKING TABLE
      ------------------------------------------

SELECT *
INTO dbo.online_retail_clean
FROM dbo.online_retail_raw;

     
              -- 3.1.1 Verify Working Table Record Count

SELECT 
    'Original Table' AS TableName,
    COUNT (*) AS TotalRecords
FROM dbo.online_retail_raw

UNION ALL 

SELECT 
   'Working Table',
    COUNT (*)
FROM dbo.online_retail_clean;


-- FINDINGS:
-- 1. Original table contains 541,909 records.
-- 2. Working table contains 541,909 records.
-- 3. Both tables have matching record counts.

-- ACTIONS:
-- 1. Working table successfully created.
-- 2. Original table remains unchanged.
-- 3. Proceed with data cleaning using dbo.online_retail_clean.


    
    -- (3.2): DUPLICATE RECORDS ASSESSMENT AND REMOVAL
   --------------------------------------------------------- 

WITH DuplicateCheck AS 
(
SELECT *,
    ROW_NUMBER () OVER (PARTITION BY InvoiceNo,StockCode,Description,Quantity,
                        InvoiceDate,UnitPrice,CustomerID,Country ORDER BY (SELECT NULL)) AS RowNum
FROM dbo.online_retail_clean
)
SELECT *
FROM DuplicateCheck
WHERE RowNum > 1;


                -- 3.2.2 Remove Duplicate Records from Working Table

DECLARE @DeletedRows INT;

WITH DuplicateCheck AS 
(
SELECT *,
    ROW_NUMBER () OVER (PARTITION BY InvoiceNo,StockCode,Description,Quantity,
                        InvoiceDate,UnitPrice,CustomerID,Country ORDER BY (SELECT NULL)) AS RowNum
FROM dbo.online_retail_clean
)
DELETE
FROM DuplicateCheck
WHERE RowNum > 1;

SET @DeletedRows = @@ROWCOUNT;

SELECT @DeletedRows AS DeletedDuplicateRecords;


               -- 3.2.3 Verify Duplicate Removal

SELECT
    COUNT(*) AS RemainingRecords
FROM dbo.online_retail_clean;


-- FINDINGS:
-- 1. Initial working table records: 541,909.
-- 2. Duplicate occurrences removed: 5,268.
-- 3. Remaining records: 536,641.

-- ACTIONS:
-- 1. Removed additional duplicate copies.
-- 2. Retained one occurrence of each identical record.
-- 3. Original table remains unchanged.



       -- (3.3): HANDLING MISSING VALUES
  ------------------------------------------------------

            -- 3.3.1 Assess Missing InvoiceNo Values

SELECT 
    COUNT (*) AS Totalrecords,
    SUM (CASE WHEN InvoiceNo IS NULL THEN 1 ELSE 0 END ) AS MissinginvoiceNo
FROM dbo.online_retail_clean;

/*
FINDINGS:
1. The cleaned working table contains 536,641 records.
2. No missing InvoiceNo values were identified.

ACTIONS:
1. No records required modification or deletion.
2. All records were retained.
3. No further cleaning action required for InvoiceNo.
*/


               -- 3.3.2 Assesing Missing Description Values 

SELECT 
    COUNT (*) AS TotalRecords,
    SUM (CASE WHEN Description IS NULL THEN 1 ELSE 0 END ) AS MissingDescription
FROM dbo.online_retail_clean;

/*
FINDINGS:
1. The working table contains 536,641 records.
2. 1,454 records have missing Description values.

ACTIONS:
1. Identified missing descriptions for further investigation.
2. No descriptions were assumed or fabricated.
3. No records modified or deleted.
*/


                      -- 3.3.2.1 Investigate the Missing Description Values 

SELECT *
FROM dbo.online_retail_clean
WHERE Description IS NULL;

/*
FINDINGS:
1. Identified 1,454 records with missing Description values.
2. The affected records contain different StockCodes.
3. The sample records include both positive and negative quantities.
4. Several sampled records also have zero UnitPrice and missing CustomerID.
5. The missing descriptions require further investigation using StockCode.

ACTIONS:
1. Flagged the 1,454 records for further investigation.
2. Retained the original StockCodes and other available information.
3. No descriptions were fabricated or automatically assigned.
4. No records modified or deleted.
*/


                     -- 3.3.2.2 Check Whether Missing Descriptions Have Valid Alternatives

WITH MissingDescription AS 
(
    SELECT 
        StockCode,
        COUNT (*) AS MissingDescriptionRecords
    FROM dbo.online_retail_clean
    WHERE Description IS NULL
    GROUP BY StockCode
),

AvailableDescription AS 
(
    SELECT 
        StockCode,
        COUNT (DISTINCT Description) AS AvailableDescriptionRecords
    FROM dbo.online_retail_clean
    WHERE Description IS NOT NULL
    GROUP BY StockCode
)

SELECT 
    m.StockCode,
    m.MissingDescriptionRecords,
    COALESCE (a.AvailableDescriptionRecords,0) AS AvailableDescriptionRecords
FROM MissingDescription AS m
LEFT JOIN AvailableDescription AS a
ON m.StockCode = a.StockCode
ORDER BY MissingDescriptionRecords DESC;


/*
FINDINGS:
1. Identified 960 StockCodes associated with missing Description values.
2. StockCode 23084 has 10 missing-description records and 7 available descriptions.
3. StockCode 35965 has 10 missing-description records and 4 available descriptions.
4. StockCode 22084 has 9 missing-description records and 1 available description.
5. StockCode 22451 has 6 missing-description records and 1 available description.
6. Some StockCodes have multiple available descriptions, requiring further investigation.

ACTIONS:
1. Identified StockCodes with missing descriptions and available alternatives.
2. Flagged StockCodes with multiple descriptions for further investigation.
3. No descriptions were automatically assigned.
4. No records modified or deleted.
*/


                   -- 3.3.2.3 Investigating the StockCode with the Highest Number of Missing Descriptions 

SELECT 
    Description,
    COUNT (*) AS DescriptionOccurence
FROM dbo.online_retail_clean
WHERE StockCode = '23084'
GROUP BY Description
ORDER BY DescriptionOccurence DESC;


/*
FINDINGS:
1. StockCode 23084 has 10 records with missing Description values.
2. RABBIT NIGHT LIGHT is the dominant description, appearing 1,032 times.
3. Seven distinct non-NULL descriptions are associated with this StockCode.
4. Six less frequent descriptions appear to represent operational notes
   rather than standard product descriptions.
5. The available descriptions do not provide sufficient certainty
   to automatically replace all missing values.

ACTIONS:
1. Flagged the 10 missing descriptions for further review.
2. Retained the existing descriptions without modification.
3. No descriptions were automatically assigned.
4. No records modified or deleted.
*/



                /*
                DATA CLEANING DECISION – MISSING PRODUCT DESCRIPTIONS

                FINDINGS:
                1. Identified 1,454 records with missing Description values.
                2. Some StockCodes have alternative descriptions available.
                3. Certain StockCodes are associated with multiple descriptions,
                   including operational notes.
                4. The available dataset does not provide an authoritative
                   product reference source for resolving every missing value.

                ACTIONS:
                1. Retained missing descriptions where the correct product
                   description could not be established.
                2. Flagged ambiguous StockCodes for further investigation.
                3. Recommended validation against an official product master
                   table or inventory reference maintained by the business.
                4. No descriptions were fabricated or automatically assigned
                   without sufficient evidence.
                */



          -- 3.3.3 Assess Missing CustomerID Values 

SELECT 
    COUNT (*) AS TotalRecords,
    SUM (CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS MissingCustomerID
FROM dbo.online_retail_clean


/*
FINDINGS:
1. The working table contains 536,641 records.
2. Identified 135,037 records with missing CustomerID values.
3. Missing CustomerIDs represent approximately 25.16%
   of the working dataset.
4. Missing CustomerIDs may affect customer-level analysis,
   including customer segmentation and repeat purchase analysis.

ACTIONS:
1. Flagged records with missing CustomerIDs for cleaning review.
2. Retained all records pending a documented handling decision.
3. No CustomerIDs were fabricated or assigned.
4. No records modified or deleted during this assessment.
*/



        -- (3.4) HANDLING INVALID NUMERICAL VALUES 
   --------------------------------------------------------------------------------------
        
                   -- 3.4.1 Assess Quantity Records 

SELECT 
    COUNT (*) AS TotalRecords,
    SUM (CASE WHEN Quantity > 0 THEN 1 ELSE 0 END) AS PositiveQuantity,
    SUM (CASE WHEN Quantity = 0 THEN 1 ELSE 0 END ) AS ZeroQuantity,
    SUM (CASE WHEN Quantity < 0 THEN 1 ELSE 0 END ) AS NegativeQuantity
FROM dbo.online_retail_clean

/*
FINDINGS:
1. The working table contains 536,641 records.
2. Identified 526,054 records with positive quantities.
3. Identified 10,587 records with negative quantities.
4. No records with zero quantities were identified.
5. Negative quantities represent approximately 1.97%
   of the working dataset.
6. Negative quantities may represent returns, cancellations
   or inventory adjustments.

ACTIONS:
1. Flagged negative quantity records for further review.
2. Retained negative quantities to preserve transaction information.
3. No quantity values were changed or fabricated.
4. No records modified or deleted during this assessment.
*/


                          -- 3.4.1.1 Investigate Negative Quantity Records

SELECT TOP 20 *
FROM dbo.online_retail_clean
WHERE Quantity < 0
ORDER BY Quantity ASC;


/*
FINDINGS:
1. Examined 20 records with the most negative quantities.
2. Identified descriptions indicating damaged, discarded
   or unsalable inventory.
3. Some records contain operational notes relating to
   stock corrections and printing defects.
4. Some negative quantity records have cancellation-related
   invoice identifiers beginning with 'C'.
5. Some records have missing CustomerID and Description values.
6. Negative quantities therefore represent different
   transaction circumstances and cannot all be classified
   as customer returns.

ACTIONS:
1. Flagged negative quantity records for appropriate handling.
2. Retained negative quantities to preserve transaction context.
3. Recommended distinguishing cancellations, returns and
   inventory adjustments during business analysis.
4. No quantity values were changed.
5. No records modified or deleted.
*/


           -- 3.4.2 Assess UnitPrice Records

SELECT
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN UnitPrice > 0 THEN 1 ELSE 0 END) AS PositiveUnitPrice,
    SUM(CASE WHEN UnitPrice = 0 THEN 1 ELSE 0 END) AS ZeroUnitPrice,
    SUM(CASE WHEN UnitPrice < 0 THEN 1 ELSE 0 END) AS NegativeUnitPrice
FROM dbo.online_retail_clean;

/*
FINDINGS:
1. The working table contains 536,641 records.
2. Identified 534,129 records with positive UnitPrice values.
3. Identified 2,510 records with zero UnitPrice values.
4. Identified 2 records with negative UnitPrice values.
5. Zero and negative prices account for approximately 0.47%
   of the working dataset.

ACTIONS:
1. Flagged zero and negative UnitPrice records for review.
2. Retained all records pending further investigation.
3. No UnitPrice values were changed.
4. No records modified or deleted.
*/

               
                   -- 3.4.2.1 Investigate Negative UnitPrice Records

SELECT *
FROM dbo.online_retail_clean
WHERE UnitPrice < 0;

/*
FINDINGS:
1. Identified 2 records with negative UnitPrice values.
2. Both records have StockCode 'B' and Description 'Adjust bad debt'.
3. Both records have a UnitPrice of -11,062.06.
4. Both records have Quantity = 1 and missing CustomerID values.
5. The transactions occurred on 12 August 2011, one minute apart.

ACTIONS:
1. Classified the records as non-standard financial adjustments
   requiring business interpretation.
2. Retained both records pending confirmation of their accounting treatment.
3. No UnitPrice values were changed.
4. No records modified or deleted.
*/

-- 3.4.2.2 Investigate Zero UnitPrice Records

SELECT TOP 20 *
FROM dbo.online_retail_clean
WHERE UnitPrice = 0
ORDER BY Quantity DESC;


/*
FINDINGS:
1. Identified 2,510 records with UnitPrice = 0.
2. The sample contains product transactions, missing descriptions,
   unclear descriptions and operational adjustment notes.
3. Some records contain descriptions referring to credit and
   transaction corrections.
4. Several records also have missing CustomerID values.

ACTIONS:
1. Retained zero UnitPrice records because they may represent
   legitimate free items or non-standard business transactions.
2. Flagged these records for business review where necessary.
3. No UnitPrice values were changed.
4. No records modified or deleted.
*/


        -- (3.5): DATA TYPE CORRECTION
 ---------------------------------------------------------------------------

      -- 3.5.1 Review the current data types 

 SELECT 
    COLUMN_NAME,
    DATA_TYPE
 FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_SCHEMA = 'dbo'
        AND TABLE_NAME = 'online_retail_clean'

/*
FINDINGS:
1. Reviewed the data types of all 8 columns in the working table.
2. InvoiceNo, StockCode, Description and Country are stored as NVARCHAR.
3. InvoiceDate is stored as DATETIME.
4. CustomerID is stored as INT.
5. Quantity and UnitPrice are currently stored as FLOAT.
6. FLOAT may introduce precision issues, particularly when storing
   monetary values such as UnitPrice.

ACTIONS:
1. Retained the existing data types pending further validation.
2. Flagged Quantity for review before possible conversion to INT.
3. Flagged UnitPrice for review before possible conversion to DECIMAL(18,2).
4. No data types were changed during this assessment.
5. No records were modified or deleted.
*/


          -- 3.5.2 Check Numeric Values Before Data Type Conversion

SELECT 
    COUNT (*) AS TotalRecords,
    SUM (CASE WHEN Quantity <> FLOOR (Quantity) THEN 1 ELSE 0 END ) AS QuantitiesNotWholeNumbers,
    SUM (CASE WHEN UnitPrice <> ROUND (UnitPrice,2) THEN 1 ELSE 0 END ) AS UnitPriceMorethanTwoDecimal
FROM dbo.online_retail_clean


/*
FINDINGS:
1. Assessed 536,641 records in the working table.
2. Identified 0 records with fractional Quantity values.
3. Identified 4 records with UnitPrice values containing
   more than two decimal places.

ACTIONS:
1. Confirmed that Quantity can be converted to INT without
   losing fractional values.
2. Flagged the 4 UnitPrice records for inspection before
   conversion to DECIMAL(18,2).
3. No data types or values were changed during this check.
*/


                        -- 3.5.2.1 Investigate the Four Unit Price with more than two Decimal Places 

SELECT *
FROM dbo.online_retail_clean
WHERE UnitPrice <> ROUND (UnitPrice,2);


/*
FINDINGS:
1. Identified 4 records with UnitPrice values containing
   more than two decimal places.
2. All 4 records have a UnitPrice of 0.001.
3. Three records relate to PADS TO MATCH ALL CUSHIONS.
4. One record relates to BANK CHARGES.

ACTIONS:
1. Retained the original UnitPrice values to preserve precision.
2. Avoided rounding 0.001 to 0.00 because this would change
   the original transaction values.
3. No UnitPrice values were modified.
4. No records were deleted.
*/



        -- 3.5.3 Convert Quantity to INT

ALTER TABLE dbo.online_retail_clean
ALTER COLUMN Quantity INT NULL;

        
        -- 3.5.4 Convert Unit Price to Decimal

ALTER TABLE dbo.online_retail_clean
ALTER COLUMN UnitPrice DECIMAL(18,3) NULL;


/*
FINDINGS:
1. Successfully converted Quantity from FLOAT to INT.
2. Successfully converted UnitPrice from FLOAT to DECIMAL(18,3).
3. Verified that both columns now have their intended data types.
4. Preserved the original three-decimal UnitPrice values.

ACTIONS:
1. Applied appropriate numeric data types to the working table.
2. Used INT for Quantity because no fractional values were identified.
3. Used DECIMAL(18,3) for UnitPrice to preserve values such as 0.001.
4. Original raw table remains unchanged.
*/



     -- 3.5.6 Validate Converted Numeric Columns

SELECT
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS MissingQuantity,
    SUM(CASE WHEN UnitPrice IS NULL THEN 1 ELSE 0 END) AS MissingUnitPrice,
    MIN(Quantity) AS MinimumQuantity,
    MAX(Quantity) AS MaximumQuantity,
    MIN(UnitPrice) AS MinimumUnitPrice,
    MAX(UnitPrice) AS MaximumUnitPrice
FROM dbo.online_retail_clean;

/*
FINDINGS:
1. The working table contains 536,641 records.
2. No missing values were introduced in Quantity or UnitPrice.
3. Quantity ranges from -80,995 to 80,995.
4. UnitPrice ranges from -11,062.060 to 38,970.000.
5. Both columns retained their values after data type conversion.

ACTIONS:
1. Confirmed successful conversion of Quantity to INT.
2. Confirmed successful conversion of UnitPrice to DECIMAL.
3. Retained negative quantities and prices for business interpretation.
4. No additional modifications or deletions were required.
*/


           -- (3.6):  STANDARDIZATION OF CATEGORICAL VALUES 
   ---------------------------------------------------------------------------------------

        -- 3.6.1 Preview Country Values for Standardization

SELECT
    Country,
    COUNT(*) AS TotalRecords
FROM dbo.online_retail_clean
WHERE Country IN ('EIRE', 'RSA', 'USA')
GROUP BY Country
ORDER BY Country;

/*
FINDINGS:
1. Identified three Country values requiring standardization.
2. EIRE contains 8,184 records.
3. RSA contains 58 records.
4. USA contains 291 records.
5. A total of 8,533 records require standardization.

ACTIONS:
1. Identified the following standard country names:
   - EIRE -> Ireland
   - RSA  -> South Africa
   - USA  -> United States
2. Confirmed the affected records before making changes.
3. No records were modified or deleted during this preview.
4. Proceed to update the Country values in the working table.
*/


             -- 3.6.1.1 Standardize Country Values

BEGIN TRANSACTION;

UPDATE dbo.online_retail_clean
SET Country = CASE WHEN Country = 'EIRE' THEN 'Ireland'
                   WHEN Country = 'RSA' THEN 'South Africa'
                   WHEN Country = 'USA' THEN 'United States'
               END 
WHERE Country IN ('EIRE','RSA','USA');

SELECT @@ROWCOUNT AS UpdatedRecords;

COMMIT TRANSACTION;

/*
FINDINGS:
1. Successfully updated 8,533 records.
2. EIRE was standardized to Ireland (8,184 records).
3. RSA was standardized to South Africa (58 records).
4. USA was standardized to United States (291 records).
5. The actual update count matched the expected count.

ACTIONS:
1. Standardized the three identified Country values.
2. Applied changes only to dbo.online_retail_clean.
3. Preserved the original raw table.
4. No records were deleted.
*/

            -- 3.6.1.2 Validate Standardized Country Values

SELECT 
    Country,
    COUNT (*) AS TotalRecords
FROM dbo.online_retail_clean
WHERE Country IN ('EIRE','RSA','USA','United States','Ireland','South Africa')
GROUP BY Country

/*
FINDINGS:
1. Confirmed successful standardization of all three Country values.
2. Ireland contains 8,184 records.
3. South Africa contains 58 records.
4. United States contains 291 records.
5. Total standardized records: 8,533.
6. No old country labels remain among the six values checked.

ACTIONS:
1. Validated the updated Country values.
2. Confirmed that the updated record counts match the initial assessment.
3. No further action required for these three country values.
*/


     -- 3.6.2 Standardize Product Descriptions with Unnecessary Spaces

SELECT
    Description,
    COUNT(*) AS AffectedRecords
FROM dbo.online_retail_clean
WHERE Description <> LTRIM(RTRIM(Description))
GROUP BY Description
ORDER BY AffectedRecords DESC;


/*FINDINGS:
  1. Identified 12 product descriptions containing unnecessary
     leading or trailing spaces.
  2. The affected descriptions accounted for 1,255 records.

  ACTIONS:
  1. Remove unnecessary leading and trailing spaces.
  2. Preserve the original wording and internal spacing.
  
*/

                -- 3.6.2.1 Remove the leading and trailing spaces 

UPDATE dbo.online_retail_clean
SET Description = LTRIM(RTRIM(Description))
WHERE Description <> LTRIM(RTRIM(Description));


/*ACTIONS:
  1. Removed unnecessary leading and trailing spaces.
  2. Preserved the original wording and internal spacing.
  3. NULL descriptions were not modified.
  4. The raw source table remained unchanged.
*/




       -- 3.6.3 Review Product Description Consistency

SELECT
    StockCode,
    Description,
    COUNT(*) AS DescriptionOccurrences
FROM dbo.online_retail_clean
WHERE StockCode = '23084'
GROUP BY
    StockCode,
    Description
ORDER BY DescriptionOccurrences DESC;


/*
FINDINGS:
1. StockCode 23084 contains 1,048 records.
2. Identified 8 description categories, including NULL.
3. RABBIT NIGHT LIGHT is the dominant description, appearing 1,032 times.
4. Identified 10 records with missing descriptions.
5. Six other descriptions appear once each and contain operational
   or unclear references.

ACTIONS:
1. Identified RABBIT NIGHT LIGHT as the dominant product description.
2. Flagged the 10 missing descriptions for further review.
3. Retained operational and unclear descriptions without modification.
4. No records were updated or deleted during this review.
*/


                      -- 3.6.3.1 Assess StockCodes with Multiple Descriptions

SELECT
    COUNT(*) AS AffectedStockCodes
FROM
(
    SELECT StockCode
    FROM dbo.online_retail_clean
    WHERE StockCode IS NOT NULL
    GROUP BY StockCode
    HAVING COUNT(DISTINCT Description) > 1
) AS MultipleDescriptions;

/*
FINDINGS:
1. Identified 644 StockCodes associated with multiple descriptions.
2. These inconsistencies may include product description variations,
   missing descriptions and operational notes.
3. StockCode 23084 was reviewed as an example.
4. Its dominant description was RABBIT NIGHT LIGHT, appearing 1,032 times.
5. The remaining descriptions require an authoritative product reference
   before automatic standardization can be justified.

ACTIONS:
1. Retained existing descriptions where the correct replacement
   could not be independently verified.
2. Flagged the 644 StockCodes for potential product master data review.
3. No automatic description replacements were performed.
4. No records were deleted.
*/



          -- (3.7):  DATA CLEANING VALIDATION 
    ----------------------------------------------------------------------------------

     -- 3.7.1 Validate Final Record Counts

SELECT 
    (SELECT COUNT (*) FROM dbo.online_retail_raw) AS RawRecords,
    (SELECT COUNT (*) FROM dbo.online_retail_clean) AS CleanedRecords,
    (SELECT COUNT (*) FROM dbo.online_retail_raw) -
    (SELECT COUNT (*) FROM dbo.online_retail_clean) RawsRemoved;


/*
FINDINGS:
1. The original raw table contains 541,909 records.
2. The cleaned working table contains 536,641 records.
3. A total of 5,268 records were removed during duplicate removal.
4. The record count reduction matches the duplicate assessment
   completed in Phase 2.

ACTIONS:
1. Confirmed that the cleaned table has the expected record count.
2. Preserved the original raw table unchanged.
3. No further action required.
*/

-- 3.7.2 Validate Remaining Exact Duplicate 

WITH DuplicateCheck AS 
(
SELECT *,
    ROW_NUMBER () OVER (PARTITION BY InvoiceNo,StockCode,Description,Quantity,InvoiceDate,
                        UnitPrice,CustomerID,Country ORDER BY (SELECT NULL) ) AS RowNum
FROM dbo.online_retail_clean
) 
SELECT *
FROM DuplicateCheck
WHERE RowNum > 1;


/*
FINDINGS:
1. The duplicate validation returned zero records.
2. No exact duplicate records remain in the cleaned working table.

ACTIONS:
1. Confirmed successful duplicate removal.
2. Retained one occurrence of each exact duplicate group.
3. No further action required.
*/



     -- 3.7.3 Validate Standardized Country Values

SELECT
    Country,
    COUNT(*) AS TotalRecords
FROM dbo.online_retail_clean
WHERE Country IN ('EIRE', 'RSA', 'USA')
GROUP BY Country;



/*
FINDINGS:
1. No records containing the old country values EIRE, RSA, or USA
   remain in the cleaned working table.
2. The country standardization was successful.

ACTIONS:
1. Confirmed the updated country values.
2. Preserved other country categories without unsupported changes.
3. No further action required.
*/



     -- 3.7.4 Validate Final Data Types

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'online_retail_clean'
AND COLUMN_NAME IN ('Quantity', 'UnitPrice');


/*
FINDINGS:
1. Quantity is stored as INT.
2. UnitPrice is stored as DECIMAL(18,3).
3. Both columns retain nullable settings.

ACTIONS:
1. Confirmed successful data type conversion.
2. Preserved three decimal places in UnitPrice.
3. No further action required.
*/


-- 3.7.5 Validate Final Working Table Structure

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'online_retail_clean'
ORDER BY ORDINAL_POSITION;

/*
FINDINGS:
1. The cleaned working table contains all 8 expected columns.
2. All column names and data types match the intended structure.
3. Quantity is INT and UnitPrice is DECIMAL(18,3).
4. No columns were lost during cleaning and transformation.

ACTIONS:
1. Confirmed the final working table structure.
2. No structural corrections required.
3. The cleaned table is ready for the next project phase.
*/

