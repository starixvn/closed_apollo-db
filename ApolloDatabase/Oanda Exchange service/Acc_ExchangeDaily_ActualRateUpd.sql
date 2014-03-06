/****** Object:  StoredProcedure [dbo].[Acc_ExchangeDaily_ActualRateUpd]    Script Date: 03/06/2014 01:44:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Acc_ExchangeDaily_ActualRateUpd    Script Date: 12/23/2013 2:26:52 PM ******/
ALTER PROCEDURE [dbo].[Acc_ExchangeDaily_ActualRateUpd]
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
Created: 20140306@Dan
Task : Daily update ActualRate of ExchangeDaily
DB: SVRTRANS/TransDB
Revisions:	
	
*/		
SET NOCOUNT ON
DECLARE @exchange TABLE(id int identity(1,1), exchangeid int,MultipliedBy int)
DECLARE @date smalldatetime
DECLARE @tmpTable TABLE(currency INT, actualrate FLOAT)
set @date = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)


--1 update ExchangeDaily actualrate from table exchange for tomorrow
UPDATE e
SET e.actualrate = ex.actualrate
FROM
    ExchangeDailyOanda e WITH (ROWLOCK,UPDLOCK)
    INNER JOIN exchange ex (NOLOCK) ON e.ExchangeId = ex.exchangeid AND e.ExchangeDate =DATEADD(dd,1,@date)

--2 update ExchangeDaily actualrate from table exchange for today
UPDATE e
SET e.actualrate = ex.actualrate
FROM
    ExchangeDailyOanda e WITH (ROWLOCK,UPDLOCK)
    INNER JOIN exchange ex (NOLOCK) ON e.ExchangeId = ex.exchangeid AND e.ExchangeDate = @date


--3 update yesterday actualrate  from bettrans
INSERT INTO @tmpTable(currency,actualrate)
SELECT DISTINCT currency, actualrate
FROM dbo.bettrans WITH (NOLOCK) 
WHERE winlostdate = DATEADD(dd,-1,@date) 

IF EXISTS(
	SELECT currency 
	FROM @tmpTable
	GROUP BY currency
	HAVING COUNT(currency) > 1
	)
BEGIN
	SELECT @ErrMsg = 'There are more than 1 actual rate for a currency in bettrans table on date: ' + DATEADD(dd,-1,@date)
				 ,@ErrCode = 100			
	RETURN
END	

UPDATE e
SET e.actualrate = b.actualrate
FROM 
	ExchangeDailyOanda e WITH (ROWLOCK,UPDLOCK) 
	INNER JOIN @tmpTable b ON e.ExchangeId = b.currency AND e.ExchangeDate = DATEADD(dd,-1,@date)
	
--4 update the day before yesterday actualrate from bettrans    
DELETE FROM @tmpTable

INSERT INTO @tmpTable(currency,actualrate)
SELECT DISTINCT currency, actualrate
FROM dbo.bettrans with (nolock) 
WHERE winlostdate = DATEADD(dd,-2,@date) 

IF EXISTS(
	SELECT currency 
	FROM @tmpTable
	GROUP BY currency
	HAVING COUNT(currency) > 1
	)
BEGIN
	SELECT @ErrMsg = 'There are more than 1 actual rate for a currency in bettrans table on date: ' + DATEADD(dd,-2,@date)
				 ,@ErrCode = 101

	RETURN
END	

UPDATE e
SET e.actualrate = b.actualrate
FROM ExchangeDailyOanda e WITH (ROWLOCK,UPDLOCK) 
	INNER JOIN @tmpTable b ON e.ExchangeId = b.currency AND e.ExchangeDate = DATEADD(dd,-2,@date)

GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeDaily_ActualRateUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeDaily_ActualRateUpd] TO [vnteam] AS [dbo]