ALTER PROCEDURE [dbo].[Acc_BetsSelBetList_ByTransID]	
	@TransID bigint = 0,
	@Username nvarchar(50) = '',  
	@FromDate date, 
	@ToDate date,
	@IsShowAll Bit = 0  	
AS

/*
    Created by: Sophia
	Date: 20130926
	Original:  [Acc_BetsSelBetList_ByTransID]
	Task: Select betlist by TransID and username 
	DB: SVRCSD.RepDB

	Revisions:		 
		
	Explanation's Param:
	 	- @IsDeleteAll:
			 + 0: can only delete the unsettled or refunded tickets
			 + 1: can delete all type of status 


*/
	SET NOCOUNT ON
	CREATE TABLE #Betlist (transid bigint,CustId int,username nvarchar(50),Creator Int, odds smallmoney, OddsType int, 
							transdate datetime, bettype smallint, betteam nvarchar(10),hdp1 smallmoney, hdp2 smallmoney,
							Liveindicator bit, livehomescore smallint, liveawayscore smallint, StakePositiontaking money,currency tinyint,
							status nvarchar(10), SecAcceptFlag bit,  HomeId Int, AwayId int, SportType smallint, LeagueId int, Winlost MONEY)
	---by @TransID
	 IF ISNULL(@TransID,0) <> 0
	 BEGIN 
		INSERT INTO #Betlist
		SELECT
			b.transid,
			b.CustId,
			b.username,
			b.Creator,
			b.odds,   
			b.OddsType,  
			b.transdate,
			b.bettype,
			betteam,
			hdp1,
			hdp2,
			b.Liveindicator,
			b.livehomescore,
			b.liveawayscore,
			stake as StakePositiontaking,
			b.currency, 
				CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
				 ELSE b.status 
				 END as status,
			ISNULL(SecAcceptFlag,0) SecAcceptFlag,
			m.HomeId, 
			m.AwayId, 
			m.SportType,
			m.LeagueId,
			b.Winlost
		FROM bettrans b WITH (NOLOCK)		
		INNER JOIN match m WITH (NOLOCK)
				ON M.MatchID = B.MatchID
		WHERE   B.TransID = @TransID
				AND Bettype NOT IN (9,29)
				AND B.StatusID NOT IN (101,102) -- Void, Reject
			    AND (B.StatusId IN (0,1) OR @IsShowAll = 1)
			   
	END 
	ELSE
	IF ISNULL(@Username,'') <> ''
	BEGIN 
		DECLARE @CustID INT 
		
		SELECT	@CustID = CustID 
		FROM	CustInfo WITH (NOLOCK) 
		WHERE	Username = @Username

		INSERT INTO #Betlist
		SELECT
			b.transid,
			b.CustId,
			b.username,
			b.Creator,
			b.odds,   
			b.OddsType,  
			b.transdate,
			b.bettype,
			betteam,
			hdp1,
			hdp2,
			b.Liveindicator,
			b.livehomescore,
			b.liveawayscore,
			stake as StakePositiontaking,
			b.currency, 
				CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
				 ELSE b.status 
				 END as status,
			ISNULL(SecAcceptFlag,0) SecAcceptFlag,
			m.HomeId, 
			m.AwayId, 
			m.SportType,
			m.LeagueId,
			b.Winlost
		FROM bettrans b WITH (NOLOCK)		
		INNER JOIN match m WITH (NOLOCK)
				ON M.MatchID = B.MatchID
		WHERE B.WinLostDate Between @FromDate AND @ToDate
			  AND Bettype NOT IN (9,29)
			  AND B.CustID = @CustID
			  AND B.StatusID NOT IN (101,102) -- Void, Reject
			  AND (B.StatusId IN (0,1) OR @IsShowAll = 1)
	END


	SELECT * FROM #Betlist with (NOLOCK)
	ORDER BY transid


	DROP TABLE #Betlist 
 

GO
GRANT EXECUTE ON [dbo].[Acc_BetsSelBetList_ByTransID] TO [aplweb] 
GO 