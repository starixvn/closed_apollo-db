ALTER PROCEDURE [dbo].[Age_Rpt_Credit_Old] 
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
		- 20150212@Sophia: Get Creator Name and Level
	Test string: 
		EXEC [Age_Rpt_Credit_Old]	
				@AgentId 	= 68,
				@CustId		= -1,
				@FromDate 	= '2014-10-01',
				@ToDate 	= '2015-02-15',		
				@BalanceUpDay = '2015-01-01'

 */

BEGIN 
	SET NOCOUNT ON 

	DECLARE @Credit AS TABLE (TransID BIGINT, TransDate DATETIME,	TransType NVARCHAR(20), Amount MONEY, BalanceAmount MONEY, TransDesc NVARCHAR(300), WinlostDate DATE, Creator INT)


	IF @ToDate >= DATEADD(dd, -1, @BalanceUpDay)
		SELECT @ToDate = DATEADD(dd, -1, @BalanceUpDay)

		IF @CustID = -1  ---- Agent
		BEGIN 
			INSERT INTO @Credit ( TransID, TransDate, TransType, Amount, BalanceAmount, TransDesc, WinlostDate, Creator)
			SELECT	TransID, TransDate, CASE WHEN Bettype = 22001 THEN 'Deposit' ELSE 'Draw' END AS TransType, Amount, BalanceBefore + Amount AS BalanceAmount, TransDesc, WinlostDate, Creator
			FROM	dbo.CreditTrans_BK WITH (NOLOCK)
			WHERE	AgentID = @AgentId 
					AND CustID = 0					
					AND WinlostDate BETWEEN @FromDate AND @ToDate

		END 
		ELSE IF @AgentId = -1  --- Cust
		BEGIN 
			INSERT INTO @Credit ( TransID, TransDate, TransType, Amount, BalanceAmount, TransDesc, WinlostDate, Creator)
			SELECT	TransID, TransDate, CASE WHEN Bettype = 22001 THEN 'Deposit' ELSE 'Draw' END AS TransType, Amount, BalanceBefore + Amount AS BalanceAmount, TransDesc, WinlostDate, Creator
			FROM	dbo.CreditTrans_BK WITH (NOLOCK)
			WHERE	AgentID = 0 
					AND CustID = @CustId					
					AND WinlostDate BETWEEN @FromDate AND @ToDate
	END 

	
	SELECT	C.TransID, C.TransDate, C.TransType, C.Amount, C.BalanceAmount, C.TransDesc, C.WinlostDate, C.Creator,
			ISNULL(A.Username,'') AS CreatorName, ISNULL(A.AgentLevel,0) AS CreatorLevel 
	FROM	@Credit C
		LEFT JOIN RepDB.dbo.AgentInfo A
			ON A.AgentId = C.Creator
	ORDER BY WinlostDate DESC, TransDate DESC, TransID DESC


END 

GO
GRANT EXECUTE ON [dbo].[Age_Rpt_Credit_Old] TO [aplweb] 
GO
