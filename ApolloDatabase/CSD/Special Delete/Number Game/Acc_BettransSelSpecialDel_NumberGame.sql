ALTER PROCEDURE [dbo].[Acc_BettransSelSpecialDel_NumberGame]  
	@MatchID INT,  
	@FromRefNo BIGINT,  
	@ToRefNo BIGINT,  
	@Live  VARCHAR(100) = '', -- bettype for live-ball  
	@Dead  VARCHAR(100) = ''  -- bettype for dead-ball  
AS  
/*  
Created by: Sophia
Date: 20130306
Original:  
Task: Select bets transaction need to delete (Number Game)  
DB: SVRCSD.RepDB
  
Revisions:  
	 
Explanation's Param:  
  
*/  
BEGIN  
	SET NOCOUNT ON  
  
	CREATE TABLE #SpecialDeleteBets   
	(
		transid BIGINT,  
		CustId INT,  
		username VARCHAR(30),  
		odds SMALLMONEY,   
		OddsType INT,   
		transdate DATETIME,  
		bettype SMALLINT,   
		betteam NVARCHAR(10),  
		BetId BIGINT,
		hdp1 SMALLMONEY,   
		hdp2 SMALLMONEY,  
		livehomescore SMALLINT,   
		liveawayscore SMALLINT,  
		stake MONEY,  
		winlost MONEY,  
		comm MONEY,  
		currency TINYINT,  
		status NVARCHAR(10),   
		liveindicator BIT  
	 )  
 
	
	INSERT INTO #SpecialDeleteBets   
	SELECT  
		b.transid,  
		b.CustId,  
		b.username,  
		b.odds,     
		b.OddsType,    
		b.transdate,  
		b.bettype,  
		b.betteam,  
		b.BetId,
		b.hdp1,  
		b.hdp2,  
		b.livehomescore,  
		b.liveawayscore,  
		b.stake,  		
		b.winlost - b.actual_stake as winlost,  
		b.playercomm as comm,   
		b.currency,   
		CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'  
			ELSE b.status END as status,  
		b.liveindicator  
	FROM   
		bettrans b WITH (NOLOCK)  
	WHERE  
		matchid=@matchid   
		AND b.transid BETWEEN @FromRefNo AND @ToRefNo  
		AND statusID NOT IN (101,102,121)   ---- Void, Reject, 121: dummy ticket  	
		AND  
		(     
			(  
				b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@Dead,'^'))  
				AND   
				b.liveindicator = 0   
			)  
			OR  
			(  
				b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@Live,'^'))  
				AND   
				b.liveindicator = 1   
			)  
		)    
	
  

	SELECT *   
	FROM #SpecialDeleteBets WITH (NOLOCK)  
	ORDER BY Transid  


	DROP TABLE #SpecialDeleteBets  
END  
  

GO
GRANT EXECUTE ON [dbo].[Acc_BettransSelSpecialDel_NumberGame] TO [aplweb] AS [dbo]
GO
--GRANT VIEW DEFINITION ON [dbo].[Acc_BettransSelSpecialDel_NumberGame] TO [vnteam] AS [dbo]