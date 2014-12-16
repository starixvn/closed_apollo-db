CREATE PROCEDURE [dbo].[Age_Rpt_Credit_Old] 
	@AgentId INT = - 1
	,@CustId INT = - 1
	,@FromDate DATE
	,@ToDate DATE
	,@BalanceUpDay DATE
AS
 /*
    Created	: Sophia
	Date	: 20141112
    Task	: Credit Report Old data 
    DB		: SVRARC/ArchiveDB

    Revisions: 

	Test string: 
		EXEC [Age_Rpt_Credit_Old]	
				@AgentId 	= -1,
				@CustId		= 60,
				@FromDate 	= '2014-10-01',
				@ToDate 	= '2014-11-15',		
				@BalanceUpDay = '2014-11-01'

 */

BEGIN 
	SET NOCOUNT ON 

	DECLARE @Credit AS TABLE ( TransID BIGINT, TransDate DATETIME,	TransType NVARCHAR(20), Amount MONEY, BalanceAmount MONEY, TransDesc NVARCHAR(300), WinlostDate DATE)


	IF @ToDate >= DATEADD(dd, -1, @BalanceUpDay)
		SELECT @ToDate = DATEADD(dd, -1, @BalanceUpDay)

		IF @CustID = -1  ---- Agent
		BEGIN 
			INSERT INTO @Credit ( TransID, TransDate, TransType, Amount, BalanceAmount, TransDesc, WinlostDate)
			SELECT	TransID, TransDate, CASE WHEN Bettype = 22001 THEN 'Deposit' ELSE 'Draw' END AS TransType, Amount, BalanceBefore + Amount AS BalanceAmount, TransDesc, WinlostDate
			FROM	dbo.CreditTrans_BK WITH (NOLOCK)
			WHERE	AgentID = @AgentId 
					AND CustID = 0					
					AND WinlostDate BETWEEN @FromDate AND @ToDate

		END 
		ELSE IF @AgentId = -1  --- Cust
		BEGIN 
			INSERT INTO @Credit ( TransID, TransDate, TransType, Amount, BalanceAmount, TransDesc, WinlostDate)
			SELECT	TransID, TransDate, CASE WHEN Bettype = 22001 THEN 'Deposit' ELSE 'Draw' END AS TransType, Amount, BalanceBefore + Amount AS BalanceAmount, TransDesc, WinlostDate
			FROM	dbo.CreditTrans_BK WITH (NOLOCK)
			WHERE	AgentID = 0 
					AND CustID = @CustId					
					AND WinlostDate BETWEEN @FromDate AND @ToDate
		END 

	
	SELECT * FROM @Credit
	ORDER BY WinlostDate DESC, TransDate DESC, TransID DESC


END 

GO
GRANT EXECUTE ON [dbo].[Age_Rpt_Credit_Old] TO [aplweb] 
GO
