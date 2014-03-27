USE [ProdDB]
GO
/****** Object:  StoredProcedure [dbo].[Task_BackupUserLog]    Script Date: 3/27/2014 2:39:12 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Task_BackupUserLog]
	@Mode int = 0
AS

IF @Mode NOT IN (1,2) Return
-- @Mode
-- 1 = select
-- 2 = delete

SET NOCOUNT ON

Declare @tmpdate datetime, @maxLogID bigint, @MinLogID bigint
SET @tmpdate = CONVERT(nvarchar(10), DATEADD(day, -1, CURRENT_TIMESTAMP), 120)

-- delete new table
SELECT @MaxLogID = isnull(Max(LogID),0), @MinLogID = isnull(Min(LogID),0)
FROM dbo.UserLog_P (nolock)
WHERE LogDate < @tmpDate

--IF @MinLogID + 5000000 < @MaxLogID SET @MaxLogID = @MinLogID + 5000000
IF @MinLogID + 100000 < @MaxLogID SET @MaxLogID = @MinLogID + 100000

IF @Mode = 1
	SELECT logid, userid, doing, logdate, Matchid, Oddsid, Extend
	FROM dbo.UserLog_P with (nolock)
	WHERE LogID < @MaxLogID

ELSE IF @Mode = 2
BEGIN
	Declare @loop varchar(1)
	SET @loop = 'y'
	WHILE @loop = 'y'
	BEGIN
		BEGIN TRANSACTION
			DELETE TOP (1000) FROM dbo.UserLog_P
			WHERE LogID < @MaxLogID

			IF @@ROWCOUNT = 0 SET @loop = 'n'
		COMMIT TRANSACTION
	END

	PRINT 'Total records deleted UserLog: ' + CAST((@MaxLogID - @MinLogID) as varchar(20))
END

