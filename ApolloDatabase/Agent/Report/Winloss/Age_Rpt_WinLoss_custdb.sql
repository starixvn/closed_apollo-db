USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Rpt_WinLoss_custdb]    Script Date: 9/20/2013 4:50:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Rpt_WinLoss_custdb]
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
	   - 201307298@Sophia: Add ActualTOAfter (Effective Stake) 
	   - 20130920@Edward : change select position taking from SVRCUST.CustDB
    */
    
SET NOCOUNT ON


CREATE TABLE #WinLossAgent ( Username NVARCHAR(50), AgentID INT, IsAgent BIT, Share SMALLINT, BetCount BIGINT, BetAmount MONEY, CommBase MONEY, Winlost MONEY, PlayerComm MONEY, MemberTotal MONEY, AWinLost MONEY, AComm MONEY, ATotal MONEY, DownlineEffStake MONEY, GrossTotal MONEY, UplineEffStake MONEY, UplineTotal MONEY)
CREATE TABLE #WinLossMember ( Username NVARCHAR(50), AgentID INT, IsAgent BIT, Share SMALLINT, BetCount BIGINT, BetAmount MONEY, CommBase MONEY,  Winlost MONEY, PlayerComm MONEY, MemberTotal MONEY, AWinLost MONEY, AComm MONEY, ATotal MONEY, DownlineEffStake MONEY, GrossTotal MONEY, UplineEffStake MONEY, UplineTotal MONEY)

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
		EXEC Age_Rpt_WinLoss_SuperViewAgent_custdb @AgentID = @AgentID, @FromDate = @FromDate, @ToDate = @ToDate, 
										@MoveBetDay =@MoveBetDay, @BalanceUpDay = @BalanceUpDay, @Sporttypes = @Sporttypes, @Bettypes = @Bettypes 
END
ELSE 
BEGIN
	--********************************
	-- Agent Winloss
	--********************************

	EXEC Age_Rpt_WinLoss_AgentViewAgent_custdb @AgentID = @AgentID, @FromDate = @FromDate, @ToDate = @ToDate, 
										@MoveBetDay =@MoveBetDay, @BalanceUpDay = @BalanceUpDay, @Sporttypes = @Sporttypes, @Bettypes = @Bettypes
	

	--********************************
	---Member winloss
	--********************************	
	EXEC Age_Rpt_WinLoss_AgentViewCust_custdb @AgentID = @AgentID, @FromDate = @FromDate, @ToDate = @ToDate, 
										 @MoveBetDay =@MoveBetDay, @BalanceUpDay = @BalanceUpDay, @Sporttypes = @Sporttypes, @Bettypes = @Bettypes
END

---delete data no need
DELETE	#WinLossAgent 
WHERE	ISNULL(BetAmount,0) = 0
		AND ISNULL(CommBase,0) = 0
		AND ISNULL(Winlost,0) = 0
		AND ISNULL(PlayerComm,0) = 0
		AND ISNULL(MemberTotal,0) = 0
		AND ISNULL(AWinLost ,0) = 0
		AND ISNULL(AComm ,0) = 0
		AND ISNULL(ATotal ,0) = 0 
		AND ISNULL(DownlineEffStake ,0) = 0
		AND ISNULL(GrossTotal ,0) = 0
		AND ISNULL(UplineEffStake ,0) = 0
		AND ISNULL(UplineTotal ,0) = 0
		


DELETE	#WinLossMember 
WHERE	ISNULL(BetAmount ,0) = 0
		AND ISNULL( CommBase ,0) = 0
		AND ISNULL( Winlost ,0) = 0
		AND ISNULL( PlayerComm ,0) = 0
		AND ISNULL( MemberTotal ,0) = 0
		AND ISNULL( AWinLost ,0) = 0
		AND ISNULL( AComm ,0) = 0
		AND ISNULL( ATotal ,0) = 0		
		AND ISNULL( UplineEffStake ,0) = 0
		AND ISNULL( UplineTotal ,0) = 0



----- Get Data  
SELECT	Username, AgentId, isAgent, Share,	
		SUM(BetCount) as BetCount,	
		SUM(BetAmount) as BetAmount,	
		SUM(CommBase) as CommBase,	
		SUM(Winlost) as Winlost,	
		SUM(PlayerComm) as PlayerComm,
		SUM(MemberTotal) as MemberTotal,	
		SUM(AWinLost) as  AWinLost, 
		SUM(AComm) as AComm,
		SUM(ATotal) as ATotal,			
		SUM(DownlineEffStake) as DownlineEffStake,
		SUM(GrossTotal) as GrossTotal,
		SUM(UplineEffStake) as UplineEffStake,
		SUM(UplineTotal) as UplineTotal
FROM	#WinLossAgent
GROUP BY Username, AgentId, isAgent, Share
UNION ALL
SELECT	Username, AgentId, isAgent, Share,
		SUM(BetCount) as BetCount,	
		SUM(BetAmount) as BetAmount,	
		SUM(CommBase) as CommBase,	
		SUM(Winlost) as Winlost,	
		SUM(PlayerComm) as PlayerComm,
		SUM(MemberTotal) as MemberTotal,	
		SUM(AWinLost) as  AWinLost, 
		SUM(AComm) as AComm,
		SUM(ATotal) as ATotal,			
		SUM(DownlineEffStake) as DownlineEffStake,
		SUM(GrossTotal) as GrossTotal,
		SUM(UplineEffStake) as UplineEffStake,
		SUM(UplineTotal) as UplineTotal
FROM	#WinLossMember 
GROUP BY Username, AgentId, isAgent, Share
ORDER BY IsAgent DESC, Share ASC, Username ASC
 


DROP TABLE #WinLossAgent
DROP TABLE #WinLossMember

DROP TABLE #BettypeList
DROp TABLE #SportsList




