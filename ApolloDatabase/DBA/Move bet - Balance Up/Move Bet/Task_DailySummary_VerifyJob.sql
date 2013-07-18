/****** Object:  StoredProcedure [dbo].[Task_DailySummary_VerifyJob]    Script Date: 07/17/2013 23:11:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_DailySummary_VerifyJob]
AS


	Declare @WeekDay tinyint
	SET @WeekDay = DATEPART(weekday, CURRENT_TIMESTAMP)

	Declare @Todaym1 datetime, @Todaym2 datetime, @Todaym3 datetime, @Todaym4 datetime
	SET @Todaym1 = DATEADD(day, -1, CONVERT(varchar(10), CURRENT_TIMESTAMP, 120))
	SET @Todaym2 = DATEADD(day, -1, @Todaym1)
	SET @Todaym3 = DATEADD(day, -1, @Todaym2)
	SET @Todaym4 = DATEADD(day, -1, @Todaym3)

	-- Server Time : Monday morning (2)
	-- Local Time  : Monday's afternoon
	IF @WeekDay = 2
	BEGIN
		EXEC dbo.Task_DailySummary_Verify @Todaym4 -- Thursday
	END
	-- Server Time : Tuesday (3)
	-- Local Time  : Tuesday's afternoon
	ELSE IF @WeekDay = 3
	BEGIN
		EXEC dbo.Task_DailySummary_Verify @Todaym4 -- Friday
		EXEC dbo.Task_DailySummary_Verify @Todaym3 -- Saturday
	END
	-- Server Time : Wednesday (4)
	-- Local Time  : Wednesday's afternoon
	ELSE IF @WeekDay = 4
	BEGIN
		EXEC dbo.Task_DailySummary_Verify @Todaym3 -- Sunday
		EXEC dbo.Task_DailySummary_Verify @Todaym2 -- Monday
	END
	-- Server Time : Friday (6)
	-- Local Time  : Friday's afternoon
	ELSE IF @WeekDay = 6
	BEGIN
		EXEC dbo.Task_DailySummary_Verify @Todaym3 -- Tuesday
		EXEC dbo.Task_DailySummary_Verify @Todaym2 -- Wednesday
		--EXEC dbo.Task_DailySummary_Verify @Todaym1 -- Thursday
	END

	ELSE
	BEGIN
		RETURN -1
	END





GO
GRANT VIEW DEFINITION ON [dbo].[Task_DailySummary_VerifyJob] TO [vnteam] AS [dbo]