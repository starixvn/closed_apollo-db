ALTER FUNCTION [dbo].[Lrf_f_GetExchangeDaily]
    (
      @fromdate DATETIME,
      @todate DATETIME
      
    )
RETURNS @tempDate TABLE (exchangedate DATETIME,ExchangeId INT,Code VARCHAR(5),MYR FLOAT, USD FLOAT, EUR FLOAT, CNY FLOAT, actualrate FLOAT, UNIQUE CLUSTERED(exchangedate,exchangeid))
AS

 /*
	Created: 20131013@Dan
	Task : Get exchange daily for LRF reports. The values are the same in 1 month
	DB: SVRSCD.RepDB
	Original:  DB052.bodb02, DB06.bodb02 [Lrf_f_GetExchangeDaily] 

	Revisions:	

	 

*/
BEGIN

DECLARE @tmpFromDate DATETIME, @tmpToDate DATETIME, @maxExchangeDate DATETIME, @tmpDate DATETIME, @gapDate DATETIME
DECLARE @i INT
 
 --SELECT @maxExchangeDate=MAX(exchangedate) FROM ExchangeDailyOanda (NOLOCK)
SELECT @maxExchangeDate = CONVERT(varchar(10),CURRENT_TIMESTAMP, 120)


SET @tmpFromDate = @fromdate
SET @i = 0


WHILE (datediff (m,@tmpFromDate,@todate)>=0)
BEGIN
	IF @i = 1
	BEGIN
		SET @tmpFromDate = CAST(CONVERT(VARCHAR(10),DATEADD(dd,-(DAY(@tmpFromDate)-1),@tmpFromDate),111) AS DATETIME)
	END

	SET @tmpToDate = CAST(CONVERT(VARCHAR(10),  DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,@tmpFromDate)+1,0)), 111) AS DATETIME)

	IF @tmpToDate>@maxExchangeDate SET @tmpToDate=@maxExchangeDate
	
	SET @tmpDate = @tmpFromDate
	
	WHILE (@tmpDate<=@tmpToDate AND @tmpDate<=@todate)
	BEGIN
		INSERT INTO @tempDate (exchangedate,ExchangeId,Code,MYR, USD, EUR, CNY, actualrate)
		SELECT @tmpDate,ExchangeId,Code,MYR, USD, EUR, CNY, actualrate
		FROM ExchangeDailyOanda WITH (NOLOCK)
		WHERE ExchangeDate = @tmpToDate
	
		SET @tmpDate = DATEADD(dd,1,@tmpDate)
	END

	SET @i = @i + 1
	SET @tmpFromDate = DATEADD(m,1,@tmpFromDate)
END



RETURN 

END

GO
GRANT SELECT  ON [dbo].[Lrf_f_GetExchangeDaily] TO [aplweb]
GO   
  