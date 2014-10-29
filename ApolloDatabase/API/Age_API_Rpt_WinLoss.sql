ALTER PROCEDURE [dbo].[Age_API_Rpt_WinLoss]
(	
	@RptType	TINYINT = 1,
	@UserId		INT,
	@UserType	TINYINT = 1,
	@FromDate	DATE,
	@ToDate		DATE,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(1000) = '' OUTPUT
)
AS
/*
Created: 20141021@Sophia
Task : API - Get Winloss report
DB: SVRAGE.RepDB 
Original: Age_Rpt_WinLoss

Revisions: 
   

Param's Explanation: 
	@RptType	:	1 = summarize (applicable to member and agent)
					2 = agent's direct downline agents
					3 = agent's direct members

	@UserType	:	0 = Member (Not Use) 
					1 = Agent 
					2 = AgentUser (Not Use)

Test string:

	EXEC [Age_API_Rpt_WinLoss] 
		@RptType	 = 3,
		@UserId		= 68,
		@UserType	= 1,
		@FromDate	= '2014-09-01 00:00:00',
		@ToDate		= '2014-10-17 00:00:00'


*/

BEGIN 
SET NOCOUNT ON

IF NOT EXISTS ( SELECT 1 FROM dbo.AgentInfo WITH (NOLOCK) WHERE AgentId = @UserId )
			BEGIN
				SELECT 
					@ErrCode = 5100, 
					@ErrMsg = 'Agent ID not exist [AgentId = ' + COALESCE(CAST(@UserId AS VARCHAR(10)), SPACE(1)) + ']'
				RETURN
			END	

DECLARE @BalanceUpDay DATE, @MoveBetDay DATE

SELECT @BalanceUpDay = MIN(WinLostDate), @MoveBetDay = MAX(WinLostDate)    
FROM  dbo.Bettrans14 WITH(NOLOCK) 

---- Agent's direct members
IF @RptType = 3  
BEGIN 

	CREATE TABLE #DetailMember  (Username NVARCHAR(50), CustId INT, IsAgent BIT, Share SMALLINT, BetCount BIGINT, BetAmount MONEY, CommBase MONEY,  Winlost MONEY, PlayerComm MONEY, MemberTotal MONEY, AWinLost MONEY, AComm MONEY, ATotal MONEY, DownlineEffStake MONEY, GrossTotal MONEY, UplineEffStake MONEY, UplineTotal MONEY, OutstandingAmount MONEY, OutstandingShareAmount MONEY)

	INSERT INTO #DetailMember (Username, CustId, Share, BetCount, BetAmount, CommBase,  Winlost, PlayerComm, MemberTotal, AWinLost, AComm, ATotal, UplineEffStake, UplineTotal, OutstandingAmount, OutstandingShareAmount)
	EXEC Age_Rpt_WinLoss_Member @FromDate = @FromDate, @ToDate = @ToDate, @BalanceUpDay = @BalanceUpDay, @MoveBetDay = @MoveBetDay, @AgentID = @UserId,@Sporttypes='0',@Bettypes='0'

	SELECT	0 AS User_Type,
			R.CustId AS User_Id,  
			R.Username AS User_Name,
			BetAmount AS Member_Stake,
			Winlost AS Winloss_Amt,	
			CommBase AS Comm_Base_Amt,
			C.UGroup AS Comm_Type,
			D.Discount AS Comm_Rate,
			PlayerComm AS Comm_Amt,
			MemberTotal AS Total_Amt,
			Share AS Agent_Share,
			MemberTotal AS Ptu_Amt, 
			BetCount AS Bet_Count
	FROM	#DetailMember R
	INNER JOIN CustInfo C WITH (NOLOCK)
			ON C.CustId = R.CustId
	INNER JOIN SVRCUST.CustDB.dbo.CustDiscount D WITH (NOLOCK) 
			ON C.CustID = D.CustID AND D.Bettype = 1 AND D.Sporttype = 1
	
END
ELSE
BEGIN 

	CREATE TABLE #WinLossAgent ( Username NVARCHAR(50), AgentID INT, IsAgent BIT, BetCount BIGINT, BetAmount MONEY, CommBase MONEY, Winlost MONEY, PlayerComm MONEY, MemberTotal MONEY, AWinLost MONEY, AComm MONEY, ATotal MONEY, DownlineEffStake MONEY, GrossTotal MONEY, UplineEffStake MONEY, UplineTotal MONEY)
	CREATE TABLE #WinLossMember ( Username NVARCHAR(50), AgentID INT, IsAgent BIT, BetCount BIGINT, BetAmount MONEY, CommBase MONEY,  Winlost MONEY, PlayerComm MONEY, MemberTotal MONEY, AWinLost MONEY, AComm MONEY, ATotal MONEY, DownlineEffStake MONEY, GrossTotal MONEY, UplineEffStake MONEY, UplineTotal MONEY)
	
	CREATE TABLE #BettypeList (bettype SMALLINT)
	INSERT INTO #BettypeList
	SELECT val FROM dbo.strSplit_Key('0',',')

	CREATE TABLE #SportsList (Sporttype TINYINT)
	INSERT INTO #SportsList (Sporttype)
	SELECT val FROM strSplit_key ('0', ',')

	
	IF @UserId = 1--- Is Super
	BEGIN 
		
		EXEC Age_Rpt_WinLoss_SuperViewAgent @AgentID = @UserId, @FromDate = @FromDate, @ToDate = @ToDate, @BalanceUpDay = @BalanceUpDay, @MoveBetDay = @MoveBetDay,  @Sporttypes = '0', @Bettypes = '0'

	END
	ELSE 
	BEGIN

		EXEC Age_Rpt_WinLoss_AgentViewAgent @AgentID = @UserId, @FromDate = @FromDate, @ToDate = @ToDate, @MoveBetDay =@MoveBetDay, @BalanceUpDay = @BalanceUpDay, @Sporttypes = '0', @Bettypes = '0'

		EXEC Age_Rpt_WinLoss_AgentViewCust	@AgentID = @UserId, @FromDate = @FromDate, @ToDate = @ToDate, @MoveBetDay =@MoveBetDay, @BalanceUpDay = @BalanceUpDay, @Sporttypes = '0', @Bettypes = '0'

	END 
	
	

	----- ################## GET DATA ##################---------
	--- agent's direct downline agents
	IF @RptType = 2 
	BEGIN 
		SELECT	PT.AgentId, PT.MaxUpperPositionTaking
		INTO	#AgentShare
		FROM	dbo.AgentInfo A WITH (NOLOCK) 
		INNER JOIN SVRCUST.CustDB.dbo.AgentPositionTaking PT WITH (NOLOCK) 
				ON	A.AgentID = PT.AgentID 			
		WHERE	A.ParentId = @UserId 
				AND PT.Bettype = 1 
				AND PT.SportType = 1 
				AND PT.IsLive = 0 	


		----- Get Data  
		SELECT	A.isAgent AS User_Type,
				A.AgentId AS User_Id,  
				A.Username AS User_Name,
				SUM(BetAmount) AS Member_Stake,
				SUM(Winlost) AS Winloss_Amt,	
				SUM(CommBase) AS Comm_Base_Amt,
				CONVERT(VARCHAR(10),'') AS Comm_Type,
				CONVERT(MONEY,0) AS Comm_Rate,
				SUM(PlayerComm) AS Comm_Amt,
				SUM(MemberTotal) AS Total_Amt,
				PT.MaxUpperPositionTaking AS Agent_Share,
				SUM(GrossTotal) AS Ptu_Amt, 
				SUM(BetCount) AS Bet_Count
		FROM	#WinLossAgent A
		INNER JOIN #AgentShare PT
				ON PT.AgentID = A.AgentId 
		GROUP BY A.AgentId, A.Username, A.isAgent, PT.MaxUpperPositionTaking 
		ORDER BY Agent_Share ASC, Username ASC

	END			
	ELSE IF @RptType = 1 --- summarize (applicable to member and agent)
	BEGIN 
		
		DECLARE @MaxUpperPositionTaking SMALLINT, @Username NVARCHAR(50)

		SELECT	@MaxUpperPositionTaking = PT.MaxUpperPositionTaking		
		FROM	SVRCUST.CustDB.dbo.AgentPositionTaking PT WITH (NOLOCK) 							
		WHERE	PT.AgentId = @UserId 
				AND PT.Bettype = 1 
				AND PT.SportType = 1 
				AND PT.IsLive = 0 	

		SELECT	@Username = Username
		FROM	dbo.AgentInfo WITH (NOLOCK)
		WHERE	AgentId = @UserId

		 
		----- Get Data  
		SELECT	1 AS User_Type,
				@UserId AS User_Id,  
				@Username AS User_Name,
				SUM(BetAmount) AS Member_Stake,
				SUM(Winlost) AS Winloss_Amt,	
				SUM(CommBase) AS Comm_Base_Amt,
				CONVERT(NVARCHAR(1),'') AS Comm_Type,
				CONVERT(MONEY,0) AS Comm_Rate,
				SUM(PlayerComm) AS Comm_Amt,
				SUM(MemberTotal) AS Total_Amt,
				@MaxUpperPositionTaking AS Agent_Share,
				SUM(GrossTotal) AS Ptu_Amt, 
				SUM(BetCount) AS Bet_Count
		FROM	#WinLossAgent A		
		UNION ALL	
		SELECT	0 AS User_Type,
				@UserId  AS User_Id,  
				@Username AS User_Name,
				SUM(BetAmount) AS Member_Stake,
				SUM(Winlost) AS Winloss_Amt,	
				SUM(CommBase) AS Comm_Base_Amt,
				NULL AS Comm_Type,
				NULL AS Comm_Rate,
				SUM(PlayerComm) AS Comm_Amt,
				SUM(MemberTotal) AS Total_Amt,
				@MaxUpperPositionTaking AS Agent_Share,
				SUM(GrossTotal) AS Ptu_Amt, 
				SUM(BetCount) AS Bet_Count
		FROM	#WinLossMember A 
		ORDER BY User_Type DESC

	END 
	
END

END 




