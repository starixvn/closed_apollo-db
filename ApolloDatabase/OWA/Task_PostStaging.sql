ALTER PROCEDURE [dbo].[Task_PostStaging]     
AS  
/*
Created: Dan@20131015
Task: clean up staging data to save diskspace
DB: SVRREPORT/ReportDB

Revisions:
    
Param's Explanation:

*/
SET NOCOUNT ON

TRUNCATE TABLE dbo.bettrans
TRUNCATE TABLE dbo.match
TRUNCATE TABLE dbo.outright

DBCC SHRINKFILE (N'DW_staging_01', 0, TRUNCATEONLY)

