USE [UserlogDB]
GO
/****** Object:  StoredProcedure [dbo].[Task_DeleteOldLog]    Script Date: 7/25/2014 1:35:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_DeleteOldLog]
AS
BEGIN
	SET NOCOUNT ON
	Declare @tmpdate datetime, @maxLogID bigint, @MinLogID bigint, @rowcount int
	SET @tmpdate = CONVERT(nvarchar(10), CURRENT_TIMESTAMP, 120)
	SELECT @tmpdate =dateadd(m, -6, @tmpdate)

	-- delete new table
	SELECT @MaxLogID = isnull(Max(LogID),0)--, @MinLogID = isnull(Min(LogID),0)
	FROM dbo.UserLog_T (nolock)
	WHERE LogDate < @tmpDate
	

	WHILE (1=1)
	BEGIN
		DELETE TOP (10000)  dbo.UserLog_T
		WHERE LogID < @MaxLogID
		
		SELECT @rowcount=@@ROWCOUNT
		IF @rowcount=0
			BREAK
	END


	SELECT @MaxLogID = isnull(Max(LogID),0)--, @MinLogID = isnull(Min(LogID),0)
	FROM dbo.UserLog_P (nolock)
	WHERE LogDate < @tmpDate

	WHILE (1=1)
	BEGIN
		DELETE  TOP (10000) dbo.UserLog_P
		WHERE LogID < @MaxLogID
		
		SELECT @rowcount=@@ROWCOUNT
		IF @rowcount=0
			BREAK
	END
END