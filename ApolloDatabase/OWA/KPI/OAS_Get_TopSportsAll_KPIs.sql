USE [ReportDB]
GO
/****** Object:  StoredProcedure [dbo].[OAS_Get_TopSportsAll_KPIs]    Script Date: 10/28/2013 5:10:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[OAS_Get_TopSportsAll_KPIs]
    @ReportDate datetime = NULL
  
WITH RECOMPILE
AS
/*
    Created: 2131025@winnie
    Task: Get Top 3 Sports (All)
    DB: ReportDB

    Revisions:

    Param's Explanation:

*/
SET NOCOUNT ON

CREATE TABLE #Top3Sport1
(
     SportName varchar(100)   
    ,PercentTurnover float	
	,Row tinyint
)
CREATE TABLE #Top3Sport2
(
     SportName varchar(100)   
    ,PercentTurnover float	
	,Row tinyint
)
CREATE TABLE #Top3Sport11
(
     SportName varchar(100)   
    ,PercentTurnover float	
	,Row tinyint
)
CREATE TABLE #Top3Sport12
(
     SportName varchar(100)   
    ,PercentTurnover float	
	,Row tinyint
)
CREATE TABLE #Top3Sport21
(
     SportName varchar(100)   
    ,PercentTurnover float	
	,Row tinyint
)
INSERT INTO #Top3Sport1
EXEC OAS_Get_TopSports_KPIs @ReportDate = @ReportDate,	@TimeType = 1
--------
INSERT INTO #Top3Sport2
EXEC OAS_Get_TopSports_KPIs @ReportDate = @ReportDate,	@TimeType = 2
--------
INSERT INTO #Top3Sport11
EXEC OAS_Get_TopSports_KPIs @ReportDate = @ReportDate,	@TimeType = 11
--------
INSERT INTO #Top3Sport12
EXEC OAS_Get_TopSports_KPIs @ReportDate = @ReportDate,	@TimeType = 12
--------
INSERT INTO #Top3Sport21
EXEC OAS_Get_TopSports_KPIs @ReportDate = @ReportDate,	@TimeType = 21
--------

SELECT 1003 AS statID,t1.SportName AS CurrentDate,t2.SportName AS CurrentMonthMonthToDate,
t11.SportName AS LastMonthMonthToDate,t12.SportName AS LastMonthFullMonth,t21.SportName YearActual
FROM #Top3Sport21 t21 
 FULL OUTER JOIN #Top3Sport12 t12 ON t21.Row=t12.Row
 FULL OUTER JOIN #Top3Sport11 t11 ON t21.Row=t11.Row
 FULL OUTER JOIN #Top3Sport2 t2 ON t21.Row=t2.Row
 FULL OUTER JOIN #Top3Sport1 t1 ON t21.Row=t1.Row
 WHERE t21.Row=1
 UNION ALL
 SELECT 1004 AS statID,LTRIM(STR(t1.PercentTurnover,25,2)),LTRIM(STR(t2.PercentTurnover,25,2)),LTRIM(STR(t11.PercentTurnover,25,2)),LTRIM(STR(t12.PercentTurnover,25,2)),LTRIM(STR(t21.PercentTurnover,25,2))
FROM #Top3Sport21 t21 
 FULL OUTER JOIN #Top3Sport12 t12 ON t21.Row=t12.Row
 FULL OUTER JOIN #Top3Sport11 t11 ON t21.Row=t11.Row
 FULL OUTER JOIN #Top3Sport2 t2 ON t21.Row=t2.Row
 FULL OUTER JOIN #Top3Sport1 t1 ON t21.Row=t1.Row
 WHERE t21.Row=1
 UNION ALL
 SELECT 1005 AS statID,t1.SportName,t2.SportName,t11.SportName,t12.SportName,t21.SportName
FROM #Top3Sport21 t21 
 FULL OUTER JOIN #Top3Sport12 t12 ON t21.Row=t12.Row
 FULL OUTER JOIN #Top3Sport11 t11 ON t21.Row=t11.Row
 FULL OUTER JOIN #Top3Sport2 t2 ON t21.Row=t2.Row
 FULL OUTER JOIN #Top3Sport1 t1 ON t21.Row=t1.Row
 WHERE t21.Row=2
 UNION ALL
 SELECT 1006 AS statID,LTRIM(STR(t1.PercentTurnover,25,2)),LTRIM(STR(t2.PercentTurnover,25,2)),LTRIM(STR(t11.PercentTurnover,25,2)),LTRIM(STR(t12.PercentTurnover,25,2)),LTRIM(STR(t21.PercentTurnover,25,2))
FROM #Top3Sport21 t21 
 FULL OUTER JOIN #Top3Sport12 t12 ON t21.Row=t12.Row
 FULL OUTER JOIN #Top3Sport11 t11 ON t21.Row=t11.Row
 FULL OUTER JOIN #Top3Sport2 t2 ON t21.Row=t2.Row
 FULL OUTER JOIN #Top3Sport1 t1 ON t21.Row=t1.Row
 WHERE t21.Row=2
  UNION ALL
  SELECT 1007 AS statID,t1.SportName,t2.SportName,t11.SportName,t12.SportName,t21.SportName
FROM #Top3Sport21 t21 
 FULL OUTER JOIN #Top3Sport12 t12 ON t21.Row=t12.Row
 FULL OUTER JOIN #Top3Sport11 t11 ON t21.Row=t11.Row
 FULL OUTER JOIN #Top3Sport2 t2 ON t21.Row=t2.Row
 FULL OUTER JOIN #Top3Sport1 t1 ON t21.Row=t1.Row
 WHERE t21.Row=3
 UNION ALL
 SELECT 1008 AS statID,LTRIM(STR(t1.PercentTurnover,25,2)),LTRIM(STR(t2.PercentTurnover,25,2)),LTRIM(STR(t11.PercentTurnover,25,2)),LTRIM(STR(t12.PercentTurnover,25,2)),LTRIM(STR(t21.PercentTurnover,25,2))
FROM #Top3Sport21 t21 
 FULL OUTER JOIN #Top3Sport12 t12 ON t21.Row=t12.Row
 FULL OUTER JOIN #Top3Sport11 t11 ON t21.Row=t11.Row
 FULL OUTER JOIN #Top3Sport2 t2 ON t21.Row=t2.Row
 FULL OUTER JOIN #Top3Sport1 t1 ON t21.Row=t1.Row
 WHERE t21.Row=3 

 
DROP TABLE #Top3Sport1 
DROP TABLE #Top3Sport2  
DROP TABLE #Top3Sport11 
DROP TABLE #Top3Sport12  
DROP TABLE #Top3Sport21


SET NOCOUNT OFF

GO
GRANT EXECUTE ON  OAS_Get_TopSportsAll_KPIs TO aplweb
GO