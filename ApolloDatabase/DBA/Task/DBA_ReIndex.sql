/****** Object:  StoredProcedure [dbo].[DBA_ReIndex]    Script Date: 07/10/2013 05:29:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[DBA_ReIndex]
AS
-- Joe : reorganize all index with fragment > 30%
-- Dan: reorganize all index with fragment > 10 %, rebuild for fragment > 30 %

declare @database_id int
select @database_id = db_id()

declare @CMDs TABLE (rn int PRIMARY KEY IDENTITY(1,1), cmd nvarchar(1000))			

INSERT INTO @CMDs (cmd)
SELECT
'ALTER INDEX [' + i.name + '] ON [dbo].[' + tbl.name + '] ' + 
	CASE WHEN fi.avg_fragmentation_in_percent > 30 then 'REBUILD'
	ELSE 'REORGANIZE'
	END
--fi.avg_fragmentation_in_percent AS [AverageFragmentation]
FROM
sys.tables AS tbl
INNER JOIN sys.indexes AS i ON (i.index_id > 0 and i.is_hypothetical = 0) AND (i.object_id=tbl.object_id)
INNER JOIN sys.dm_db_index_physical_stats(@database_id, NULL, NULL, NULL, 'LIMITED') AS fi ON fi.object_id=CAST(i.object_id AS int) AND fi.index_id=CAST(i.index_id AS int)
WHERE
	fi.avg_fragmentation_in_percent > 10
	AND tbl.name NOT LIKE 'BalanceRecord%'
ORDER BY tbl.name, i.type_desc

declare @rn int, @cmd nvarchar(1000)
SET @rn = 1

WHILE EXISTS(SELECT 1 FROM @CMDs WHERE rn = @rn)
BEGIN
	SELECT @cmd = cmd FROM @CMDs WHERE rn = @rn
	SET @rn = @rn + 1

	EXEC sp_executesql @cmd
END

EXEC sp_updatestats
--DBCC DROPCLEANBUFFERS