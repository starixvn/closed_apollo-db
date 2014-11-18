ALTER PROCEDURE [dbo].[Age_Rpt_Credit]
	@AgentId 	INT = -1,
	@CustId		INT = -1,
	@FromDate 	DATE,
	@ToDate 	DATE,		
	@BalanceUpDay DATE
AS
 /*
    Created	: Sophia
	Date	: 20141112
    Task	: Credit Report
    DB		: SVRAGE/RepDB     

    Revisions: 

	Test string: 
		EXEC [Age_Rpt_Credit]	
				@AgentId 	= -1,
				@CustId		= 60,
				@FromDate 	= '2014-10-01',
				@ToDate 	= '2014-11-15',		
				@BalanceUpDay = '2014-11-01'

 */

BEGIN 
SET NOCOUNT ON 

DECLARE @Credit AS TABLE ( TransID BIGINT, TransDate DATETIME,	TransType NVARCHAR(20), Amount MONEY, BalanceAmount MONEY, TransDesc NVARCHAR(300) )


IF @Todate > @BalanceUpDay
BEGIN  
	INSERT INTO @Credit ( TransID, TransDate, TransType, Amount, BalanceAmount, TransDesc)
	SELECT TransID, TransDate, CASE WHEN Amount < 0  THEN 'Draw' ELSE 'Deposit' END AS TransType, Amount AS Amount, BalanceBefore + Amount AS BalanceAmount, TransDesc
	FROM dbo.CreditTrans WITH (NOLOCK)
	WHERE WinlostDate BETWEEN @FromDate AND @ToDate
		  AND ( (AgentID = @AgentId AND @CustID = -1)
				OR (CustID = @CustID AND @AgentId = -1)
			   )
END

----- BK -------
IF @FromDate < @BalanceUpDay 
BEGIN    	
	IF @ToDate >= DATEADD(dd, -1, @BalanceUpDay)
	SELECT @ToDate = DATEADD(dd, -1, @BalanceUpDay)

	INSERT INTO @Credit ( TransID, TransDate, TransType, Amount, BalanceAmount, TransDesc)
	SELECT TransID, TransDate, CASE WHEN Amount < 0  THEN 'Draw' ELSE 'Deposit' END AS TransType, Amount AS Amount, BalanceBefore + Amount AS BalanceAmount, TransDesc
	FROM SVRARC.ArchiveDB.dbo.CreditTrans_BK WITH (NOLOCK)
	WHERE WinlostDate BETWEEN @FromDate AND @ToDate
		  AND ( (AgentID = @AgentId AND @CustID = -1)
				OR (CustID = @CustID AND @AgentId = -1)
			   )
END

SELECT * FROM @Credit
ORDER BY TransDate DESC, TransID DESC


END 

GO
GRANT EXECUTE ON [dbo].[Age_Rpt_Credit] TO [aplweb] 
GO