
/*
================================================================================
PROJECT:       E-Commerce Sales, Customer Behaviour & Revenue Analysis
DATABASE:      OnlineRetailAnalytics
TOOL:          Microsoft SQL Server (SSMS)
AUTHOR:        Joseph Njoroge Ng'endo

SCRIPT NAME:   Database Setup
PROJECT PHASE: Phase 1 - Dataset Understanding & SQL Server Setup

DESCRIPTION:
Create and configure the project database, select the database,
and verify the active database.

================================================================================
*/

-- ===========================================================
      -- A) DATABASE SETUP
-- ============================================================

-- 1.1 Create the project database 

IF DB_ID('OnlineRetailAnalytics') IS NULL
BEGIN
    CREATE DATABASE OnlineRetailAnalytics;
END;
GO

-- 1.2 Select the project database

USE OnlineRetailAnalytics;
GO

-- 1.3 Confirm the active database

SELECT DB_NAME() AS CurrentDatabase;
GO

/*
============================================================
FINDINGS:
Database successfully created and verified.

ACTION:
Database is ready for the next project activity.

STATUS: COMPLETED
============================================================
*/
