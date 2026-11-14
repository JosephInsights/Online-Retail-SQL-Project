# E-Commerce Sales, Customer Behaviour & Revenue Analysis Using SQL Server

## PROJECT DEVELOPMENT & DOCUMENTATION LOG

**Project:** Online Retail Analytics

**Database:** `dbo.online_retail_raw`

**Dataset:** UCI Online Retail Dataset

**Tools:** Microsoft SQL Server (SSMS), Visual Studio Code and GitHub

**Project Status:** In Progress

**Author:** Joseph Njoroge Ng'endo

---

# 1. PROJECT OVERVIEW

## 1.1 Introduction

This project focuses on analysing an online retail business using SQL Server. The objective is to explore transactional data, assess data quality, design a relational database and perform SQL-based business analysis.

The project will use the Online Retail dataset, which contains historical online purchase transactions, including customer information, product details, quantities, prices and transaction dates.

## 1.2 Project Objectives

- Assess and improve the quality of the original dataset.
- Design and implement a relational database using four related tables.
- Demonstrate SQL skills from basic to advanced levels.
- Analyse sales performance and revenue trends.
- Understand customer purchasing behaviour.
- Evaluate product performance.
- Generate actionable business insights and recommendations.

## 1.3 Project Tools

| Tool | Purpose |
|---|---|
| SQL Server | Database creation and SQL analysis |
| SSMS | Writing and executing SQL queries |
| Visual Studio Code | Project documentation |
| GitHub | Portfolio publication and version control |

---

# 2. PROJECT DEVELOPMENT LOG

## PHASE 1: DATASET UNDERSTANDING & SQL SERVER SETUP

### 1.1 Database Creation

**Objective:**

Create a dedicated SQL Server database for the Online Retail project.

**Actions Performed:**

1. Created the OnlineRetailAnalytics database.
2. Selected the project database using the USE statement.
3. Verified the active database using DB_NAME().

**SQL Commands Used:**

- CREATE DATABASE
- USE
- SELECT DB_NAME()

**Result:**

The database was successfully created and verified in SQL Server Management Studio.

**Status:** Completed

**N/B:**

- Saved the database setup procedure in `01_Database_Setup.sql`.
- Added an IF DB_ID() condition to prevent duplicate database creation.
- The script can be safely executed again without attempting to recreate an existing database.


### 1.2 Original Dataset Structure

**Dataset:** UCI Online Retail Dataset

**File:** Online Retail.xlsx

**Worksheet:** Online Retail

**Number of transaction records:** 541909

**Number of Columns:** 8

**Columns Identified:**

1. InvoiceNo
2. StockCode
3. Description
4. Quantity
5. InvoiceDate
6. UnitPrice
7. CustomerID
8. Country

**Dataset Date Coverage:**

- Earliest Transaction: 2010-12-01
- Latest Transaction: 2011-12-09
- Coverage: December 2010 – December 2011


**Initial Observations:**

- Each row represents a product transaction.
- An invoice may contain multiple products.
- Customers can make multiple purchases.
- InvoiceDate contains date and time information.
- The dataset contains transaction, product and customer information.

**Status:** Initial inspection completed.

## PHASE 2: DATA QUALITY ASSESSMENT

### Objective

The objective of this phase was to assess the quality, completeness, consistency and structural integrity of the Online Retail dataset before performing data cleaning and exploratory analysis.

The assessment focused on identifying missing values, duplicate records, unusual numerical values, date inconsistencies, categorical inconsistencies and transaction-level integrity issues.

**Dataset:** `dbo.online_retail_raw`
**Database:** `OnlineRetailAnalytics`
**Total Records:** 541,909
**Assessment Status:** Completed

### Assessment Methodology

The assessment was conducted using SQL Server queries, including:

- `INFORMATION_SCHEMA.COLUMNS` to inspect column names and data types.
- Conditional aggregation using `SUM(CASE WHEN...)` to identify missing and unusual values.
- `ROW_NUMBER()` to identify duplicate occurrences.
- `GROUP BY` and `HAVING` to investigate repeated records and inconsistent values.
- `COUNT(DISTINCT...)` to assess invoice, customer and categorical consistency.
- Date aggregation and filtering to assess temporal consistency.
- `CASE` expressions to classify transaction types.

All checks were performed against the project's dataset. No records were intentionally deleted or modified during this phase.

### 2.1 Key Data Quality Findings

#### 3.1 Original Table Structure and Data Types

The dataset contains eight columns:

| Column      | Imported data type |
| ----------- | ------------------ |
| InvoiceNo   | NVARCHAR           |
| StockCode   | NVARCHAR           |
| Description | NVARCHAR           |
| Quantity    | FLOAT              |
| InvoiceDate | DATETIME           |
| UnitPrice   | FLOAT              |
| CustomerID  | INT                |
| Country     | NVARCHAR           |

All columns allow NULL values.

The text-based `InvoiceNo` field preserves both numeric invoice identifiers and alphanumeric identifiers, including cancellation and adjustment references.

### 2.2 Missing and Blank Values

The assessment identified:

| Column      | Missing records |
| ----------- | --------------: |
| InvoiceNo   |               0 |
| StockCode   |               0 |
| Description |           1,454 |
| Quantity    |               0 |
| InvoiceDate |               0 |
| UnitPrice   |               0 |
| CustomerID  |         135,080 |
| Country     |               0 |

Additional validation established that the 1,454 missing Description values were actual NULL values, not empty or whitespace-only strings.

No missing or blank StockCode or Country values were identified.

### 2.3 Duplicate Records

Using `ROW_NUMBER()` across all eight columns, the assessment identified:

- 5,268 additional duplicate occurrences.
- 4,879 duplicate groups.

These occurrences represent records appearing more than once with identical values across the assessed columns.

No records were deleted. Duplicate occurrences were retained for evaluation during the data cleaning phase.

### 2.4 Invalid and Inconsistent Numerical Values

The numerical assessment identified:

| Check              | Records |
| ------------------ | ------: |
| Zero Quantity      |       0 |
| Negative Quantity  |  10,624 |
| Zero UnitPrice     |   2,515 |
| Negative UnitPrice |       2 |

Further investigation established:

- Negative quantities included descriptions associated with returns, cancellations, damaged or discarded products and stock adjustments.
- Zero UnitPrice records included unclear descriptions, missing product descriptions and possible transaction corrections.
- The two negative UnitPrice records were associated with bad debt adjustments.

These values were flagged for appropriate business interpretation rather than automatically treated as errors.

### 2.5 Date and Temporal Consistency

The InvoiceDate assessment established:

- Earliest transaction date: 1 December 2010, 08:26.
- Latest transaction date: 9 December 2011, 12:50.
- Missing InvoiceDate values: 0.
- No records were identified outside the observed date range.

Repeated timestamps were also assessed:

- Repeated timestamp values: 19,018.
- Records sharing repeated timestamps: 537,667.
- Maximum records sharing one timestamp: 1,114.

Shared timestamps were not automatically classified as duplicates because multiple invoice lines can legitimately be recorded at the same time.

### 2.6 Categorical Data Consistency

**Country assessment**

The dataset contains 38 distinct country values.

The assessment identified values requiring interpretation, including:

- EIRE – alternative name for Ireland.
- RSA – abbreviation for South Africa.
- USA – abbreviation for the United States.
- European Community – a regional grouping.
- Channel Islands – a geographical grouping.
- Unspecified – an existing category requiring review.

No country values were modified during assessment.

**Product Description and StockCode assessment**

The assessment identified 644 StockCodes associated with multiple distinct product descriptions.

StockCode `23084` was investigated and found to have seven distinct non-NULL descriptions across 1,067 records, alongside records with NULL descriptions.

Some descriptions represented operational notes or adjustments rather than standard product names.

These inconsistencies were flagged for further investigation during cleaning.

### 2.7 Structural and Referential Integrity

**Invoice and transaction consistency**

The assessment identified 43 invoice numbers associated with multiple distinct transaction timestamps.

Invoice `574076` was investigated:

- Total records: 416.
- One record was recorded at 15:37.
- The remaining 415 records were recorded at 15:38.
- The timestamps differed by one minute.

The original timestamps were retained pending further evaluation.

**Customer and invoice consistency**

The assessment established:

- No invoice was associated with multiple known CustomerIDs.
- 135,080 records had missing CustomerIDs.
- 3,710 invoices were affected by missing CustomerIDs.
- All 3,710 affected invoices had missing CustomerIDs across their associated records.
- No invoices had partially missing CustomerIDs.

No customer identifiers were fabricated or assigned.

**Transaction type and invoice classification**

Invoice numbers were classified using their prefixes:

| Transaction type | Distinct invoices |     Records |
| ---------------- | ----------------: | ----------: |
| Regular          |            22,061 |     532,618 |
| Cancellation     |             3,836 |       9,288 |
| Adjustment       |                 3 |           3 |
| **Total**        |        **25,900** | **541,909** |

Invoice numbers beginning with `C` were classified as cancellations, those beginning with `A` as adjustments, and the remaining invoice numbers as regular transactions.

### 2.8 Final Data Quality Validation

The final validation confirmed the following:

| Validation                  |  Result |
| --------------------------- | ------: |
| Total records               | 541,909 |
| Distinct invoices           |  25,900 |
| Missing invoice numbers     |       0 |
| Regular transaction records | 532,618 |
| Cancellation records        |   9,288 |
| Adjustment records          |       3 |
| Missing CustomerIDs         | 135,080 |
| Missing Descriptions        |   1,454 |

The transaction classification totals reconcile with the overall dataset record count.

### Actions Taken

During the assessment:

1. Inspected and documented the dataset structure and imported data types.
2. Identified missing values and duplicate occurrences.
3. Investigated unusual numerical values and transaction adjustments.
4. Assessed date, categorical and invoice-level consistency.
5. Classified regular, cancellation and adjustment transactions.
6. Flagged identified issues for appropriate treatment during data cleaning.
7. Preserved the original records without intentionally deleting or modifying data.

### Conclusion

The data quality assessment identified several issues requiring attention before the dataset can be used reliably for business analysis.

The most significant findings include 5,268 additional duplicate occurrences, 135,080 records with missing CustomerIDs, 1,454 missing product descriptions, unusual numerical values and inconsistencies in product descriptions and invoice timestamps.

The assessment also established the transaction classification and confirmed that the dataset contains 541,909 records across 25,900 distinct invoices.

Although the dataset contains quality issues, these findings do not prevent the project from proceeding. They provide a clear basis for the next phase.

**Phase 2 Status: COMPLETED**

**Next Phase: Phase 3 – Data Cleaning and Transformation.**




# PHASE 3: DATA CLEANING AND TRANSFORMATION

## 1. Phase Overview

### Objective
The objective of this phase was to clean and transform the raw Online Retail dataset into a reliable working table suitable for business analysis.

The cleaning process focused on:
- Creating a separate working table while preserving the original dataset.
- Removing exact duplicate records.
- Managing missing values using documented business decisions.
- Evaluating and retaining unusual numerical values where their business meaning was not conclusive.
- Correcting numerical data types.
- Standardizing selected categorical values.
- Removing unnecessary spaces from product descriptions.
- Validating the final cleaned dataset.

### Database and Tables

| Item | Details |
|---|---|
| Database | OnlineRetailAnalytics |
| Source table | dbo.online_retail_raw |
| Working table | dbo.online_retail_clean |
| Original records | 541,909 |
| Final cleaned records | 536,641 |
| Columns | 8 |
| SQL environment | Microsoft SQL Server |

---

## 2. Creation of the Working Table

A separate working table was created from the original raw table using `SELECT INTO`.

The purpose was to perform all cleaning and transformation operations without modifying the original source data.

### SQL Operation

```sql
SELECT *
INTO dbo.online_retail_clean
FROM dbo.online_retail_raw;
```

### Findings
- The original raw table contained 541,909 records.
- The working table was successfully created with 541,909 records.
- Both tables initially contained the same records.

### Actions
- Created `dbo.online_retail_clean`.
- Preserved `dbo.online_retail_raw` unchanged.
- All subsequent cleaning operations were performed on the working table.

---

## 3. Removal of Exact Duplicate Records

### Objective
Identify and remove exact duplicate records while retaining one occurrence of each unique record.

### Method
Used the SQL Server `ROW_NUMBER()` window function to identify duplicate records based on all eight columns.

The duplicate identification was based on:

- InvoiceNo
- StockCode
- Description
- Quantity
- InvoiceDate
- UnitPrice
- CustomerID
- Country

Records assigned a row number greater than 1 were classified as duplicate occurrences.

### Findings

| Metric | Result |
|---|---:|
| Original records | 541,909 |
| Duplicate occurrences identified | 5,268 |
| Duplicate groups | 4,879 |
| Records remaining | 536,641 |

### Actions
- Removed 5,268 duplicate occurrences.
- Retained one occurrence from each exact duplicate group.
- Preserved the original raw table.
- Continued all subsequent cleaning operations using the reduced working table.

### Outcome
The working table contained 536,641 records after duplicate removal.

---

## 4. Missing Value Management

### Objective
Evaluate missing values in important columns and determine appropriate handling actions without introducing unsupported information.

### 4.1 InvoiceNo

**Finding:**
- No missing InvoiceNo values were identified in the working table.

**Action:**
- No cleaning action was required.

### 4.2 Description

**Finding:**
- 1,454 records had missing product descriptions.
- The affected records were associated with different StockCodes.
- Some StockCodes had multiple descriptions, including operational notes and inconsistent product descriptions.
- A review of StockCode 23084 highlighted several different descriptions associated with the same product code.

**Action:**
- Retained missing descriptions as NULL.
- Did not automatically assign descriptions based on StockCode.
- Avoided fabricating product information.
- Flagged description inconsistencies for potential future review using an authoritative product master or catalogue.

**Business decision:**

Missing product descriptions were retained because there was insufficient evidence to assign reliable replacement values.

### 4.3 CustomerID

**Finding:**
- 135,037 records had missing CustomerID values after duplicate removal.
- Missing customer identifiers represented approximately 25.16% of the cleaned dataset.

**Action:**
- Retained missing CustomerID values as NULL.
- Did not generate or assign artificial customer identifiers.
- Documented the limitation for future customer-level analysis.

**Business decision:**

Records without CustomerID remain useful for product and sales analysis, but should be treated carefully when conducting customer-level analysis.

### 4.4 Country

**Finding:**
- No missing or blank Country values were identified during the initial data quality assessment.

**Action:**
- No missing-value correction was required.

---

## 5. Numerical Value Cleaning and Transformation

### Objective
Apply appropriate cleaning decisions to Quantity and UnitPrice without removing legitimate business transactions.

The decisions were based on the findings from Phase 2.

### 5.1 Quantity

**Finding:**
- The working table contained positive and negative quantities.
- No zero quantities remained after duplicate removal.
- Negative quantities represented approximately 1.97% of the working table.
- Sample descriptions included operational notes such as damaged, discarded, or unsalable inventory.
- Some negative quantities were associated with cancellation invoices.

**Action:**
- Retained negative quantities.
- Did not automatically delete negative transactions.
- Preserved the original transaction context.

**Business decision:**

Negative quantities can represent returns, cancellations, inventory corrections, or other operational adjustments. Removing them could distort sales and transaction analysis.

### 5.2 UnitPrice

**Finding:**

| Category | Records |
|---|---:|
| Positive UnitPrice | 534,129 |
| Zero UnitPrice | 2,510 |
| Negative UnitPrice | 2 |
| Total | 536,641 |

The two negative UnitPrice records were associated with `Adjust bad debt`, StockCode `B`, and invoice numbers A563186 and A563187.

Four records contained UnitPrice values with more than two decimal places. These values were 0.001 and were associated with PADS and BANK CHARGES records.

**Action:**
- Retained zero UnitPrice records.
- Retained the two negative UnitPrice adjustment records.
- Preserved values with three decimal places.
- Did not automatically delete or overwrite unusual prices.

**Business decision:**

Zero prices may represent promotional or other non-standard transactions. Negative prices may represent financial adjustments. Their treatment should depend on the business definition of revenue and accounting requirements.

---

## 6. Data Type Correction and Categorical Standardization

### 6.1 Data Type Correction

**Objective:**

Convert numerical columns into appropriate SQL Server data types for accurate calculations and analysis.

Initial data types:
- Quantity: FLOAT
- UnitPrice: FLOAT

Before conversion, the values were assessed to confirm whether the selected data types would preserve the underlying information.

**Findings:**
- No fractional Quantity values were identified.
- Four UnitPrice records contained three decimal places.

**Actions:**

Quantity was converted to INT:

```sql
ALTER TABLE dbo.online_retail_clean
ALTER COLUMN Quantity INT NULL;
```

UnitPrice was converted to DECIMAL(18,3):

```sql
ALTER TABLE dbo.online_retail_clean
ALTER COLUMN UnitPrice DECIMAL(18,3) NULL;
```

**Reason for the selected data types:**
- INT is appropriate for whole-number quantities.
- DECIMAL(18,3) preserves the three decimal places found in UnitPrice.
- Using DECIMAL avoids the floating-point representation issues associated with FLOAT for financial calculations.

**Post-conversion validation:**

| Validation | Result |
|---|---:|
| Total records | 536,641 |
| Missing Quantity | 0 |
| Missing UnitPrice | 0 |
| Minimum Quantity | -80,995 |
| Maximum Quantity | 80,995 |
| Minimum UnitPrice | -11,062.060 |
| Maximum UnitPrice | 38,970.000 |

Both conversions were successful.

### 6.2 Country Standardization

**Objective:**

Standardize selected country values to improve consistency in geographical reporting.

The following country values were selected for correction:

| Original Value | Standardized Value | Records Updated |
|---|---|---:|
| EIRE | Ireland | 8,184 |
| RSA | South Africa | 58 |
| USA | United States | 291 |
| **Total** | | **8,533** |

**Actions:**
- Replaced EIRE with Ireland.
- Replaced RSA with South Africa.
- Replaced USA with United States.
- Preserved other country categories, including European Community, Channel Islands, and Unspecified.

**Business decision:**

Only country values with clear and defensible replacements were standardized. Other categories were retained because their treatment required additional business context.

**Validation:**

A follow-up query confirmed that none of the original aliases remained.

### 6.3 Product Description Consistency

**Finding:**
- The initial assessment identified 644 StockCodes associated with multiple non-NULL descriptions.
- Some descriptions represented operational notes rather than standard product names.

**Action:**
- Did not automatically replace or standardize ambiguous descriptions.
- Retained the original descriptions and missing values.
- Identified the need for an authoritative product master for reliable future standardization.

### 6.4 Product Description Whitespace Cleaning

**Objective:**

Remove unnecessary leading and trailing spaces from product descriptions.

**Finding:**
- Identified 12 product descriptions containing unnecessary spaces.
- These affected 1,255 records.

**Action:**

Used `LTRIM()` and `RTRIM()` to remove unnecessary spaces at the beginning and end of descriptions.

```sql
UPDATE dbo.online_retail_clean
SET Description = LTRIM(RTRIM(Description))
WHERE Description <> LTRIM(RTRIM(Description));
```

**Validation:**
- The follow-up validation returned zero remaining affected records.
- Internal spacing and original wording were preserved.
- NULL descriptions were not modified.

---

## 7. Final Data Cleaning Validation

### Objective

Confirm that the cleaning and transformation operations were successfully completed and that the working table is structurally ready for the next project phase.

### 7.1 Final Record Count Validation

| Metric | Result |
|---|---:|
| Original raw records | 541,909 |
| Final cleaned records | 536,641 |
| Records removed | 5,268 |

The reduction in records matched the number of exact duplicate occurrences removed.

### 7.2 Remaining Duplicate Validation

**Result:**
- Zero remaining exact duplicate records were identified.

**Conclusion:**
The duplicate removal operation was successful.

### 7.3 Country Standardization Validation

**Result:**
- No records containing EIRE, RSA, or USA remained.

**Conclusion:**
The selected country standardization operations were successful.

### 7.4 Final Data Type Validation

| Column | Final Data Type |
|---|---|
| Quantity | INT |
| UnitPrice | DECIMAL(18,3) |

Both columns retained their intended nullable settings.

### 7.5 Final Working Table Structure

The final working table contains the expected eight columns:

| Column | Final Data Type |
|---|---|
| InvoiceNo | NVARCHAR |
| StockCode | NVARCHAR |
| Description | NVARCHAR |
| Quantity | INT |
| InvoiceDate | DATETIME |
| UnitPrice | DECIMAL(18,3) |
| CustomerID | INT |
| Country | NVARCHAR |

All eight expected columns were confirmed through `INFORMATION_SCHEMA.COLUMNS`.

---

## 8. Final Phase 3 Results

| Activity | Outcome |
|---|---|
| Working table creation | Successful |
| Exact duplicate removal | 5,268 removed |
| Missing InvoiceNo | None |
| Missing Description | Retained and documented |
| Missing CustomerID | Retained and documented |
| Negative Quantity | Retained |
| Zero UnitPrice | Retained |
| Negative UnitPrice | Retained for accounting interpretation |
| Quantity conversion | FLOAT to INT |
| UnitPrice conversion | FLOAT to DECIMAL(18,3) |
| Country standardization | 8,533 records updated |
| Product description whitespace | 1,255 records corrected |
| Remaining exact duplicates | Zero |
| Final table structure | 8 expected columns confirmed |

## 9. Business and Technical Decisions

The following decisions were made during the cleaning process:

1. The raw source table was preserved to maintain data integrity and traceability.
2. Only exact duplicate occurrences were removed.
3. Missing CustomerID and Description values were retained rather than replaced with fabricated information.
4. Negative quantities were retained because they may represent returns, cancellations, or inventory adjustments.
5. Zero prices were retained because their business meaning was not sufficiently established to justify deletion.
6. Negative prices were retained as potential financial adjustments pending accounting interpretation.
7. UnitPrice was converted to DECIMAL(18,3) to preserve the original precision.
8. Only clearly identifiable country aliases were standardized.
9. Ambiguous product descriptions were not automatically replaced.
10. Unnecessary leading and trailing spaces were removed from product descriptions.

These decisions were intended to preserve the information contained in the original transactions while improving the consistency and usability of the working dataset.

---

## 10. Phase Conclusion

Phase 3 successfully transformed the original Online Retail dataset into a cleaned working table containing 536,641 records and eight columns.

The process removed exact duplicate occurrences, corrected selected data types, standardized clearly identifiable country aliases, and removed unnecessary whitespace from product descriptions.

Missing values and unusual transaction values were retained where their business meaning could not be established confidently. These limitations were documented to support appropriate interpretation during subsequent analysis.

The final validation checks confirmed:
- The expected final record count.
- No remaining exact duplicates.
- Successful country standardization.
- Correct numerical data types.
- The expected eight-column table structure.

**Final working table:** `dbo.online_retail_clean`

**Phase 3 Status: COMPLETED**

The cleaned working table is ready to proceed to the next project phase: **Exploratory Data Analysis (EDA) and Business Analysis**.



# PHASE 4: EXPLORATORY DATA ANALYSIS (EDA) AND BUSINESS ANALYSIS

**Project:** Online Retail Sales Analysis  
**Database:** OnlineRetailAnalytics  
**Source Table:** `dbo.online_retail_clean`  
**SQL Environment:** Microsoft SQL Server  
**Currency:** GBP (£)  
**Status:** Completed

---

## 1. Phase Objective

The objective of Phase 4 was to analyze the cleaned online retail dataset and identify meaningful business insights relating to:

- Overall sales and revenue performance.
- Monthly and quarterly sales trends.
- Product performance and revenue contribution.
- Customer purchasing behavior and revenue contribution.
- Geographic sales distribution.
- Daily and weekday sales patterns.
- Cancellation activity and its impact on sales.

SQL aggregations, conditional expressions, Common Table Expressions (CTEs), window functions, and date functions were used throughout the analysis.

## 2. Revenue Classification and Definition

Before conducting the analysis, transactions were classified using their invoice numbers.

| Transaction category | Identification | Treatment |
|---|---|---|
| Regular sales | InvoiceNo does not begin with C or A | Included in regular sales analysis |
| Cancellation | InvoiceNo begins with C | Analyzed separately |
| Adjustment | InvoiceNo begins with A | Analyzed separately or excluded from regular sales |

Revenue was calculated using:

`SUM(Quantity * UnitPrice)`

The dataset uses GBP, so no currency conversion was necessary.

### Initial transaction classification findings

| Category | Records | Invoices | Transaction value |
|---|---:|---:|---:|
| Regular sales | 527,387 | 22,061 | £10,631,048.744 |
| Cancellations | 9,251 | 3,836 | -£893,979.730 |
| Adjustments | 3 | 3 | -£11,062.060 |
| **Total** | **536,641** | **25,900** | **£9,726,006.954** |

**Business interpretation:**

Regular sales generated the majority of transaction value. However, cancellation and adjustment transactions reduced the overall net transaction value.

---

## 3. Sales Performance Analysis

### 3.1 Monthly Revenue Performance

The monthly analysis examined revenue, orders, and net quantity sold.

**Key findings:**

- November 2011 recorded the highest monthly revenue of £1,503,866.78.
- November also recorded 3,021 orders and 749,777 net units sold.
- February 2011 recorded the lowest revenue among complete months, at £522,545.56.
- Revenue increased significantly between September and November 2011.
- December 2010 and December 2011 were incomplete periods.

**Business insight:**

Sales activity strengthened considerably toward the final months of 2011, indicating a potentially important seasonal sales pattern.

### 3.2 Month-over-Month Revenue Growth

The `LAG()` window function was used to compare monthly revenue against the preceding month.

**Key findings:**

- May 2011 recorded the strongest growth at 43.27%.
- September 2011 recorded growth of 41.47%.
- March 2011 recorded growth of 37.06%.
- November 2011 recorded growth of 30.63%.
- April 2011 experienced the largest decline among the complete months, at -25.03%.
- December 2011 recorded a decline of -57.59%, but this was an incomplete month.

**Business insight:**

Revenue growth was not consistent throughout the year. Identifying the factors behind stronger and weaker months can help improve sales planning.

### 3.3 Quarterly Revenue Performance

| Quarter | Revenue |
|---|---:|
| Q4 2010 | £821,452.73 |
| Q1 2011 | £1,928,572.43 |
| Q2 2011 | £2,066,812.11 |
| Q3 2011 | £2,521,290.63 |
| Q4 2011 | £3,292,920.84 |

**Key findings:**

- Q3 2011 was the strongest complete quarter.
- Q2 recorded revenue growth of 7.17% compared with Q1.
- Q3 recorded growth of 21.99% compared with Q2.
- Q4 2011 recorded £3.29 million, but the quarter was incomplete because the dataset ends on December 9.
- Q4 2010 was also incomplete because the dataset begins on December 1.

**Business insight:**

The complete quarters demonstrate improving revenue performance throughout 2011.

---

## 4. Product Performance Analysis

### 4.1 Top Products by Revenue

The initial product analysis identified the leading StockCode and Description combinations by revenue.

Some of the leading entries included:

| Product | Revenue |
|---|---:|
| DOTCOM POSTAGE | £206,248.77 |
| REGENCY CAKESTAND 3 TIER | £174,156.54 |
| PAPER CRAFT, LITTLE BIRDIE | £168,469.60 |
| WHITE HANGING HEART T-LIGHT HOLDER | £106,236.72 |
| PARTY BUNTING | £99,445.23 |

This initial analysis included non-merchandise entries.

### 4.2 Top 10 Physical Products by Revenue

Non-merchandise StockCodes DOT, POST, and M were excluded.

The leading physical products included:

1. Regency Cakestand 3 Tier – £174,156.54
2. Paper Craft, Little Birdie – £168,469.60
3. White Hanging Heart T-Light Holder – £106,236.72
4. Party Bunting – £99,445.23
5. Jumbo Bag Red Retrospot – £94,159.81
6. Medium Ceramic Top Storage Jar – £81,700.92
7. Rabbit Night Light – £66,870.03
8. Paper Chain Kit – £64,875.59
9. Assorted Colour Bird Ornament – £58,927.62
10. Chilli Lights – £54,096.36

**Important observation:**

Paper Craft, Little Birdie recorded an unusually high quantity of 80,995 units in one order. This was flagged for further investigation rather than automatically corrected.

### 4.3 Top Products by Quantity Sold

The highest quantities included:

| Product | Net quantity sold |
|---|---:|
| PAPER CRAFT, LITTLE BIRDIE | 80,995 |
| MEDIUM CERAMIC TOP STORAGE JAR | 78,033 |
| WORLD WAR 2 GLIDERS ASSTD DESIGNS | 54,951 |
| JUMBO BAG RED RETROSPOT | 48,375 |
| WHITE HANGING HEART T-LIGHT HOLDER | 37,876 |

**Business insight:**

Products with high sales quantities are not necessarily the same products generating the highest revenue. Both metrics are important when evaluating product performance.

### 4.4 Product Revenue Contribution

The analysis covered 5,610 product entries.

- Total revenue in the filtered product analysis: £10,268,945.27.
- Regency Cakestand contributed approximately 1.70%.
- Paper Craft, Little Birdie contributed approximately 1.64%.
- White Hanging Heart T-Light Holder contributed approximately 1.03%.
- The top 10 products collectively contributed approximately 9.44% of total product revenue.

**Business insight:**

Revenue was distributed across a broad product range rather than being concentrated in only a few products.

---

## 5. Customer Performance Analysis

### 5.1 Top Customers by Revenue

The analysis identified the customers generating the highest revenue.

Leading customers included:

| Customer ID | Revenue |
|---|---:|
| 14646 | £279,138.02 |
| 18102 | £259,657.30 |
| 17450 | £194,390.79 |
| 16446 | £168,472.50 |
| 14911 | £140,336.83 |

Customer 14911 recorded 199 orders among the leading customers, while customer 16446 generated £168,472.50 from only two orders.

**Business insight:**

Some customers contribute substantial revenue through frequent purchases, while others generate high revenue through relatively few transactions.

### 5.2 Customer Revenue Segmentation

Customers were divided into four revenue groups using `NTILE(4)`.

| Customer segment | Customers | Average revenue |
|---|---:|---:|
| Top 25% | 1,084 | £6,382.28 |
| Upper-middle 25% | 1,084 | £1,052.01 |
| Lower-middle 25% | 1,084 | £456.14 |
| Bottom 25% | 1,084 | £176.07 |

**Key finding:**

The top 25% of customers generated approximately 78.8% of total identified customer revenue.

**Business insight:**

The business depends substantially on its highest-value customers. Retention strategies should prioritize these customers while also identifying opportunities to increase spending among lower-value segments.

### 5.3 Customer Order Frequency

Customers were grouped according to their number of orders.

| Order frequency | Customers | Orders | Revenue |
|---|---:|---:|---:|
| 1 order | 1,506 | 1,506 | £627,166.70 |
| 2–5 orders | 1,965 | 5,934 | £2,335,100.64 |
| 6–10 orders | 533 | 3,959 | £1,486,674.19 |
| More than 10 orders | 332 | 7,020 | £4,295,137.11 |

**Key findings:**

- Customers with more than 10 orders represented approximately 7.66% of customers.
- This group generated approximately 49.1% of customer revenue.
- Repeat customers collectively generated approximately 90.3% of customer revenue.

**Business insight:**

Repeat purchasing is an important contributor to revenue. Customer retention and repeat-purchase campaigns should therefore be important business priorities.

### 5.4 Customer Revenue Contribution

The identified customer revenue total was £8,744,078.64 across 4,336 customers.

Leading customer contributions included:

- Customer 14646: 3.19%.
- Customer 18102: 2.97%.
- Customer 17450: 2.22%.
- Customer 16446: 1.93%.
- Customer 14911: 1.60%.

The top three customers collectively contributed approximately 8.38%.

**Business insight:**

Although a small group of customers contributes substantial revenue, no individual customer accounted for more than 4% of the identified customer revenue.

---

## 6. Geographic Performance Analysis

Revenue, orders, customers, and net quantity sold were analyzed by country.

**Key findings:**

- The United Kingdom was the leading market across revenue, customer count, order count, and quantity sold.
- UK revenue was approximately £7.24 million.
- The UK recorded 3,918 customers and 16,592 orders.
- Netherlands and Ireland were among the strongest international markets.
- Germany and France also recorded significant sales activity.
- The analysis covered 37 countries.

**Business insight:**

The United Kingdom is the business's dominant market, while international markets provide additional revenue opportunities.

**Business recommendation:**

Continue strengthening the UK market while evaluating international markets for opportunities to increase customer acquisition and revenue.

---

## 7. Time-Based Sales Analysis

### 7.1 Revenue and Order Performance by Day of the Week

| Day | Orders | Revenue |
|---|---:|---:|
| Monday | 2,835 | £1,327,760.48 |
| Tuesday | 3,160 | £1,673,648.12 |
| Wednesday | 3,438 | £1,560,549.25 |
| Thursday | 4,006 | £1,941,119.91 |
| Friday | 2,812 | £1,460,762.08 |
| Sunday | 2,168 | £780,238.80 |

**Key findings:**

- Thursday recorded the highest revenue and order count.
- Sunday recorded the lowest revenue among the returned days.
- Tuesday generated higher revenue than Wednesday despite having fewer orders.
- Saturday did not appear in the query results.

### 7.2 Daily Revenue Performance

The daily analysis identified the highest-revenue individual sales dates.

**Leading dates:**

- December 9, 2011: £184,170.66.
- September 20, 2011: £103,280.30.
- January 18, 2011: £87,130.81.

December 9 recorded the highest visible daily revenue, generated from 41 orders.

**Business insight:**

Certain dates experienced significantly stronger sales activity. These periods can be investigated to identify the underlying factors contributing to higher revenue.

### 7.3 Sales Performance by Calendar Day

The analysis grouped sales by the numerical day of the month across all months and years.

| Calendar day | Revenue |
|---|---:|
| 9th | £456,605.13 |
| 7th | £373,247.30 |
| 18th | £364,039.26 |
| 20th | £359,744.62 |
| 5th | £346,471.49 |

**Key findings:**

- The 9th recorded the highest combined revenue.
- The 7th recorded the highest order count among the visible results.
- The 18th recorded the highest quantity sold among the visible results.

**Business insight:**

Revenue, order volume, and quantity sold do not necessarily peak on the same calendar day.

---

## 8. Cancellation and Adjustment Analysis

### 8.1 Products by Cancellation Value

The analysis identified products and transaction entries with the highest cancellation values.

Leading results included:

| Entry | Cancellation value |
|---|---:|
| Amazon Fee | £23,528.59 |
| Paper Craft, Little Birdie | £168,469.60 |
| Medium Ceramic Top Storage Jar | £77,479.64 |
| Regency Cakestand 3 Tier | £9,697.05 |
| CRUK Commission | £7,933.43 |

Paper Craft, Little Birdie recorded 80,995 cancelled units from one cancellation invoice.

**Business insight:**

Some products have substantial cancellation values, and unusual cancellation quantities should be investigated. Non-merchandise transaction entries must be distinguished from physical products when interpreting the results.

### 8.2 Cancellation Rate by Product

Cancellation rates were calculated using:

Cancellation quantity / (Quantity sold + Cancellation quantity) × 100.

Leading results included:

| Entry | Cancellation rate |
|---|---:|
| Samples | 96.77% |
| Amazon Fee | 94.12% |
| Blue Padded Soft Mobile | 87.50% |
| Pink Poppy Hanging Decoration | 70.59% |
| Bank Charges | 67.57% |

**Key finding:**

Paper Craft, Little Birdie recorded 80,995 sold units and 80,995 cancelled units, giving a cancellation rate of 50%.

**Business insight:**

A high cancellation rate does not always mean a high financial impact. Cancellation percentages should be evaluated alongside quantities and values.

### 8.3 Overall Sales vs. Cancellation Performance

The final analysis compared regular sales activity with cancellation activity, excluding StockCodes DOT, POST, M, and B.

| Metric | Result |
|---|---:|
| Regular sales orders | 21,896 |
| Cancellation orders | 3,577 |
| Total quantity sold | 5,629,817 |
| Total quantity cancelled | 271,346 |
| Regular sales value | £10,268,945.27 |
| Cancellation value | £735,320.74 |
| Quantity cancellation rate | 4.60% |
| Value cancellation rate | 6.68% |

**Key findings:**

- The quantity cancellation rate was 4.60%.
- The value cancellation rate was 6.68%.
- Cancellation value represented a higher proportion of transaction value than cancellation quantity represented of total quantity.

**Business insight:**

The difference between the two cancellation rates indicates that cancelled transactions had a relatively higher value per unit than regular sales on average.

Cancellation value represents the value of cancelled transaction lines. It should not automatically be interpreted as a confirmed financial loss.

---

## 9. Consolidated Business Recommendations

Based on the findings from Phase 4, the following recommendations are proposed.

### 9.1 Sales Growth

- Investigate the factors contributing to strong sales performance in the final months of 2011.
- Use historical sales trends to support sales forecasting and inventory planning.
- Monitor monthly and quarterly revenue changes to identify potential growth opportunities.

### 9.2 Product Management

- Prioritize inventory planning for consistently high-performing products.
- Monitor both product revenue and quantity sold when making purchasing decisions.
- Investigate unusual transaction quantities, particularly Paper Craft, Little Birdie.
- Review cancellation activity for products with unusually high cancellation rates.

### 9.3 Customer Retention

- Prioritize retention of high-value customers.
- Introduce targeted campaigns to encourage repeat purchases.
- Develop strategies to increase spending among lower-revenue customer segments.
- Monitor changes in customer purchasing frequency.

### 9.4 Geographic Expansion

- Maintain strong performance in the UK market.
- Evaluate international markets with significant revenue and order activity.
- Investigate opportunities to increase customer acquisition in promising international markets.

### 9.5 Sales Timing and Promotions

- Review Thursday sales performance to understand why it is the strongest weekday.
- Investigate the high revenue recorded on December 9, 2011.
- Use calendar-day patterns as supporting information when planning promotional activities.

### 9.6 Cancellation Management

- Monitor cancellation rates by both quantity and value.
- Investigate products with high cancellation volumes and values.
- Review order processing and fulfillment procedures.
- Distinguish merchandise cancellations from fees and other transaction adjustments.
- Avoid treating all cancellation values as confirmed financial losses without payment and fulfillment information.

---

## 10. Phase 4 Conclusion

Phase 4 successfully transformed the cleaned online retail dataset into business-oriented findings using SQL Server.

The analysis identified:

- Sales trends and revenue growth patterns.
- High-performing products and product revenue contributions.
- Customer revenue concentration and purchasing frequency.
- Geographic sales distribution.
- Weekday and calendar-day sales patterns.
- Product-level and overall cancellation performance.

The findings demonstrate the importance of combining revenue, order volume, quantity sold, customer behavior, and cancellation metrics when evaluating business performance.

The results and recommendations from this phase can serve as the foundation for the next stage of the project, including data visualization and business reporting in Power BI.

**Phase 4 Status: COMPLETED**




# PHASE 5: FINAL BUSINESS REPORTING AND EXECUTIVE KPI SUMMARY

**Project:** Online Retail Sales Analysis  
**Database:** OnlineRetailAnalytics  
**Source Table:** `dbo.online_retail_clean`  
**SQL Environment:** Microsoft SQL Server  
**Currency:** GBP (£)  
**Status:** Completed

---

## 1. Phase Objective

The objective of Phase 5 was to consolidate the analytical findings from Phase 4 into business-focused reporting outputs and executive performance indicators.

The phase focused on:

1. Executive business performance summary.
2. Sales efficiency and customer value KPIs.
3. Order value distribution analysis.
4. Final executive business insights and recommendations.

The aim was to translate the SQL analysis into meaningful information that management could use for business decision-making.

## 2. Executive Business Performance Summary

### 2.1 Analysis Objective

To establish the overall business performance using key indicators covering sales orders, customers, quantity sold, sales revenue, and cancellation activity.

### 2.2 Results

| KPI | Result |
|---|---:|
| Total sales orders | 21,896 |
| Total customers | 4,363 |
| Total quantity sold | 5,629,817 |
| Total sales revenue | £10,268,945.27 |
| Total cancellation orders | 3,577 |
| Total cancellation value | £735,320.74 |

### 2.3 Findings

- The business recorded 21,896 regular sales orders.
- Total sales revenue amounted to £10,268,945.27.
- Total quantity sold was 5,629,817 units.
- The filtered transaction records contained 4,363 distinct customers.
- Cancellation activity amounted to 3,577 orders with a cancellation value of £735,320.74.

### 2.4 Interpretation

The executive summary provides an overview of the business's sales activity and cancellation performance.

The customer count represents distinct customers across all included transaction types, rather than only regular sales invoices.

## 3. Sales Efficiency and Customer Value KPIs

### 3.1 Analysis Objective

To evaluate the average value generated per order, average quantity purchased per order, and average revenue generated per identified customer.

Customers with missing CustomerID were excluded to ensure that customer revenue was calculated using identified customers only.

### 3.2 Results

| KPI | Result |
|---|---:|
| Total sales orders | 18,419 |
| Total customers | 4,336 |
| Average order value | £474.73 |
| Average units per order | 279.92 |
| Average revenue per customer | £2,016.62 |

### 3.3 Findings

- The analysis identified 18,419 sales orders from 4,336 customers.
- Average Order Value (AOV) was £474.73.
- Average quantity purchased per order was 279.92 units.
- Average revenue generated per identified customer was £2,016.62.

### 3.4 Interpretation

The results provide an indication of customer purchasing value and transaction size.

Average Order Value helps evaluate revenue generated per invoice, while average revenue per customer provides an indication of customer value.

### 3.5 Business Recommendations

- Monitor Average Order Value to identify opportunities to increase revenue per transaction.
- Develop customer retention strategies to encourage repeat purchases.
- Evaluate purchasing patterns to identify opportunities to increase customer spending.
- Use average units per order to support inventory and fulfillment planning.

## 4. Order Value Distribution Analysis

### 4.1 Analysis Objective

To understand how sales revenue is distributed across different order-value categories.

The SQL `NTILE(4)` window function was used to divide sales orders into four approximately equal groups based on order revenue.

### 4.2 Results

| Order segment | Orders | Average order value | Minimum order value | Maximum order value | Total revenue |
|---|---:|---:|---:|---:|---:|
| Top 25% – Highest value | 4,605 | £1,220.24 | £463.80 | £168,469.60 | £5,619,201.02 |
| Upper middle 25% | 4,605 | £362.66 | £301.80 | £463.66 | £1,670,053.50 |
| Lower middle 25% | 4,605 | £225.22 | £156.93 | £301.80 | £1,037,142.70 |
| Bottom 25% – Lowest value | 4,604 | £90.72 | £0.00 | £156.91 | £417,681.42 |

### 4.3 Findings

- The highest-value 25% of orders generated £5,619,201.02.
- This represented approximately 64.25% of the revenue included in the order-value analysis.
- The bottom 25% generated £417,681.42, representing approximately 4.78% of the analyzed revenue.
- Average order value ranged from £90.72 in the bottom quartile to £1,220.24 in the top quartile.
- The highest individual order value was £168,469.60.
- Some orders in the bottom quartile had zero revenue despite containing positive quantities.

### 4.4 Interpretation

The results show that revenue is concentrated among the highest-value orders.

A relatively small proportion of orders generated a substantial share of the analyzed revenue.

The unusually high order value and zero-revenue transactions require further investigation before drawing conclusions about their business implications.

### 4.5 Business Recommendations

- Prioritize retention and service quality for customers associated with high-value orders.
- Investigate unusually high-value transactions to confirm their accuracy.
- Review zero-revenue transactions to understand why positive quantities generated no revenue.
- Develop strategies to increase the average order value of lower-performing order segments.

## 5. Consolidated Executive Business Insights

The following insights summarize the findings from Phase 5.

### 5.1 Overall Sales Performance

The business generated £10.27 million in filtered regular sales revenue, supported by 21,896 sales orders.

### 5.2 Customer Value

The identified customer analysis covered 4,336 customers, with average revenue per customer of £2,016.62.

### 5.3 Order Value Distribution

The highest-value 25% of orders generated approximately 64.25% of the revenue included in the order-value analysis.

### 5.4 Cancellation Performance

Cancellation value amounted to £735,320.74, with a previously calculated value cancellation rate of 6.68%.

### 5.5 Management Recommendations

1. Strengthen customer retention strategies.
2. Improve opportunities to increase average order value.
3. Monitor high-value transactions and investigate unusual records.
4. Use customer purchasing patterns to support sales planning.
5. Monitor cancellation performance alongside regular sales activity.

## 6. Important Analytical Notes

- Regular sales invoices exclude InvoiceNo values beginning with C or A.
- Cancellation invoices begin with C.
- Adjustment invoices begin with A.
- StockCodes DOT, POST, and M were excluded from the relevant filtered reporting queries.
- StockCode B was retained because it is a valid stock code in this analysis.
- Customer-level KPIs exclude missing CustomerID records.
- Different reporting queries use different filters, so their totals should not automatically be treated as identical.
- All financial values are reported in GBP (£).
- Cancellation value represents cancelled transaction-line value and is not necessarily a confirmed financial loss.

## 7. Phase 5 Conclusion

Phase 5 successfully consolidated the findings from the SQL analysis into executive reporting indicators and business recommendations.

The analysis provided an overview of:

- Overall sales performance.
- Customer purchasing value.
- Average order performance.
- Order revenue distribution.
- Cancellation activity.
- Business opportunities and management recommendations.

The reporting outputs provide a foundation for presenting the project findings through business intelligence dashboards.

**PHASE 5 STATUS: COMPLETED**





