ALTER PROCEDURE [dbo].[Acc_ExchangeIns]	
	@exchangeid INT OUTPUT,
	@Currency nvarchar(5) = '',
	@actualrate FLOAT,
	@minbet FLOAT = 0,
	@minbetlive FLOAT = 0,
	@Description NVARCHAR(100) = '',
	@MultipliedBy int = 1,
	@UserID INT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT,
	@IP VARCHAR(15) = ''
AS
SET NOCOUNT ON
/*
Created: 20130821@Sophia
Task : Insert new currency
DB: SVRTXN.TRANSDB
Original:

Revisions:
	 
Param's Explanation:
	• @actualrate: Specify exchange-rate of the currency
	• @minbet: Specify minbet of the currency

*/
 

--check currency name
IF EXISTS (SELECT 1 FROM Exchange WITH (NOLOCK) WHERE Currency = @Currency)
BEGIN
	SELECT @ErrMsg = 'This currency name is already used.', @ErrCode = 101	
	RETURN
END

INSERT INTO exchange(actualrate, creator, Currency, minbet, minbetlive, Description, MultipliedBy)
VALUES (@actualrate, @UserID, @Currency, @minbet, @minbetlive, @Description, @MultipliedBy)


SELECT @exchangeid=@@IDENTITY

DECLARE @LogData NVARCHAR(200)
SELECT @LogData = 'Add exchange rate:'
	+  ' CurrencyName='+ ISNULL(@Currency,'') 
    +  ' ,BaseRate=' + ISNULL(convert(VARCHAR(10), @actualrate),'')  
	+  ' ,minbet='+ ISNULL(convert(VARCHAR(10), @minbet),'') 
	+  ' ,minbetlive='+ ISNULL(convert(VARCHAR(10), @minbetlive),'') 
	+  ' ,Description='+ ISNULL(@Description,'')
	+  ' ,MultipliedBy='+ ISNULL(convert(varchar(10),@MultipliedBy),'')
	

EXEC SVRLOG.LogDB.dbo.WriteLog_ExchangeRate
	@UserID = @UserID, 
	@ExchangeID = @exchangeid, 
	@actualrate = @actualrate, 
	@IP = @IP, 
	@Doing = @LogData

GO
GRANT  EXECUTE  ON [dbo].[Acc_ExchangeIns]  TO [aplweb]
GO