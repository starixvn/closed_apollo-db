ALTER PROCEDURE [dbo].[Age_Rpt_WinLoss]
	@AgentID 	INT,
	@FromDate 	DATE,
	@ToDate 	DATE,	
	@MoveBetDay DATE, 
	@BalanceUpDay DATE,	
	@Sporttypes VARCHAR(MAX) = '0',
	@Bettypes VARCHAR(MAX) = '0'
WITh RECOMPILE  	
AS
    /*
    Created	: Sophia
	Date	: 20130401
    Task	: Report Agent Winloss
    DB		: SVRAGE.RepDB
    Original SP:[Age_Rpt_WinLoss_Ag]
     

    Revisions:
       - 20130625@Sophia: Modify for Singbet
	   - 20130708@Sophia: Change SuperId from 0 to 1 (@AgentID = 1)
						  Sort by PositionTaking
	   - 20130712@Sophia: add OutStanding
	   - 20130718@Sophia: Remove OutStanding
	   - 20130726@Sophia: Improve performance
    */
    
SET NOCOUNT ON


CREATE TABLE #WinLossAgent ( Username NVARCHAR(50), AgentID INT, IsAgent BIT, PositionTaking SMALLINT, BetCount BIGINT, TurnOver MONEY, ActualTO MONEY, AWinLost MONEY, AComm MONEY, ATotal MONEY, GrossTotal MONEY, UplineTotal MONEY)
CREATE TABLE #WinLossMember ( Username NVARCHAR(50), AgentID INT, IsAgent BIT,  PositionTaking SMALLINT, BetCount BIGINT, TurnOver MONEY, ActualTO MONEY, AWinLost MONEY, AComm MONEY, ATotal MONEY, GrossTotal MONEY, UplineTotal MONEY)

CREATE TABLE #BettypeList (bettype SMALLINT)
INSERT INTO #BettypeList
SELECT val FROM dbo.strSplit_Key(@Bettypes,',')

CREATE TABLE #SportsList (Sporttype TINYINT)
INSERT INTO #SportsList (Sporttype)
SELECT val FROM strSplit_key (@Sporttypes, ',')


IF @AgentId = 1
BEGIN 
	--********************************
	----Super view
	--********************************
		EXEC Age_Rpt_WinLoss_SuperViewAgent  @AgentID = @AgentID, @FromDate = @FromDate, @ToDate = @ToDate, 
										@MoveBetDay =@MoveBetDay, @BalanceUpDay = @BalanceUpDay, @Sporttypes = @Sporttypes, @Bettypes = @Bettypes 
END
ELSE 
BEGIN
	--********************************
	---- Agent Winloss
	--********************************

	EXEC Age_Rpt_WinLoss_AgentViewAgent @AgentID = @AgentID, @FromDate = @FromDate, @ToDate = @ToDate, 
										@MoveBetDay =@MoveBetDay, @BalanceUpDay = @BalanceUpDay, @Sporttypes = @Sporttypes, @Bettypes = @Bettypes
	

	--********************************
	-----Member winloss
	--********************************	
	EXEC Age_Rpt_WinLoss_AgentViewCust @AgentID = @AgentID, @FromDate = @FromDate, @ToDate = @ToDate, 
										 @MoveBetDay =@MoveBetDay, @BalanceUpDay = @BalanceUpDay, @Sporttypes = @Sporttypes, @Bettypes = @Bettypes
END

---delete data no need
DELETE	#WinLossAgent 
WHERE	TurnOver IS NULL 
		AND ActualTO IS NULL
		AND AWinLost IS NULL
		AND AComm IS NULL
		AND ATotal IS NULL
		AND GrossTotal IS NULL
		AND UplineTotal IS NULL


DELETE	#WinLossMember 
WHERE	TurnOver IS NULL 
		AND ActualTO IS NULL
		AND AWinLost IS NULL
		AND AComm IS NULL
		AND ATotal IS NULL
		AND GrossTotal IS NULL
		AND UplineTotal IS NULL


----- Get Data  
SELECT	Username, AgentId, isAgent, PositionTaking,
		SUM(BetCount) as BetCount,	
		SUM(TurnOver) as TurnOver,
		SUM(ActualTO) as ActualTO,
		SUM(GrossTotal) as GrossTotal,
		SUM(AWinLost) as  AWinLost, 
		SUM(AComm) as AComm,
		SUM(ATotal) as ATotal,				
		SUM(UplineTotal) as UplineTotal
FROM	#WinLossAgent
GROUP BY Username, AgentId, isAgent, PositionTaking
UNION ALL
SELECT	Username, AgentId, isAgent, PositionTaking,
		SUM(BetCount) as BetCount,	
		SUM(TurnOver) as TurnOver,
		SUM(ActualTO) as ActualTO,
		SUM(GrossTotal) as GrossTotal,
		SUM(AWinLost) as  AWinLost, 
		SUM(AComm) as AComm,
		SUM(ATotal) as ATotal,		
		SUM(UplineTotal) as UplineTotal
FROM	#WinLossMember 
GROUP BY Username, AgentId, isAgent, PositionTaking
ORDER BY IsAgent DESC, PositionTaking ASC, Username ASC
 


DROP TABLE #WinLossAgent
DROP TABLE #WinLossMember

DROP TABLE #BettypeList
DROp TABLE #SportsList



GO
GRANT EXECUTE ON [dbo].[Age_Rpt_WinLoss] TO [aplweb]
GO 
