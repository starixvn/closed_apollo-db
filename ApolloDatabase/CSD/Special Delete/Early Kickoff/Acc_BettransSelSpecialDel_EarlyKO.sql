ALTER PROCEDURE [dbo].[Acc_BettransSelSpecialDel_EarlyKO]
	@MatchID int,  
	@KickOffDate datetime,
	@hdp smallmoney = 9999,  
	@bettypes varchar(1000) = '',   
	@betteam1378 varchar(10) = 'ALL',  
	@betteam515 varchar(10) = 'ALL',  
	@betteam430 varchar(120) = '',
	@betteam6 varchar(120) = '',
	@betteam14 varchar(120) = '',
	@betteam16 varchar(120) = ''
AS  
/*  
  Created by: Sophia
	Date: 20130718
	Original:  
	Task: Select bet tickets early kickoff need to delete
	DB: SVRCSD/RepDB

	Revisions:		
		 - 20131022@Sophia: Get CurrencyName not user currency
		
	Explanation's Param:
	    --- @SAFilter: 
	    --  + 0: All tickets
		--  + 1: Normal tickets only
	    --  + 2: SA tickets only
     		
*/
BEGIN
	SET NOCOUNT ON 
	
	CREATE TABLE #SpecialDeleteBets (transid bigint,SubTransid bigint,refno bigint
	,custid int, username nvarchar(50), odds smallmoney,modds smallmoney, OddsType int, transdate datetime,bettype smallint, betteam nvarchar(10),hdp1 smallmoney, hdp2 smallmoney,livehomescore smallint, liveawayscore smallint
	,Actualstake Money, Stake money, CurrencyName varchar(50) ,status nvarchar(10),  HomeId Int, AwayId int, SportType smallint, LeagueId int)  
	
	CREATE TABLE #SpecialDeleteBetms (transid bigint,SubTransid bigint,refno bigint
	,custid int, username nvarchar(50), odds smallmoney,modds smallmoney, OddsType int, transdate datetime,bettype smallint, betteam nvarchar(10),hdp1 smallmoney, hdp2 smallmoney,livehomescore smallint, liveawayscore smallint
	,Actualstake Money, Stake money, CurrencyName varchar(50) , status nvarchar(10), HomeId Int, AwayId int, SportType smallint, LeagueId int, ParlayType smallint)  

	IF EXISTS( SELECT convert(int,val) FROM dbo.strSplit(@bettypes,'^') Where convert(int,val) in (4,30) )	
		INSERT INTO #SpecialDeleteBets 
		SELECT  
			b.transid,
			b.transid AS SubTransID,
			b.refno,
			b.custid,
			b.username,  
			b.odds, 
			b.modds,    
			b.OddsType,    
			b.transdate,  
			b.bettype,  
			b.betteam,  
			b.hdp1,  
			b.hdp2,  
			b.livehomescore,  
			b.liveawayscore,  			
			b.Actual_stake,
			b.stake, 
			b.CurrencyName,   				
			CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
				 ELSE b.status 
				 END as status,  
			--ISNULL(SecAcceptFlag,0) SecAcceptFlag,
			m.HomeId, 
			m.AwayId, 
			m.SportType,
			m.LeagueId
		FROM bettrans b with (NOLOCK)	
			INNER JOIN Match m WITH (NOLOCK) ON b.MatchId = m.MatchId
			INNER JOIN dbo.strSplit(@bettypes,'^') AS fb ON b.bettype=fb.val
		WHERE	b.matchid=@matchid   
			AND b.transdate>=@KickOffDate
			AND b.statusID NOT IN (101,102)
			AND b.liveindicator=0
			AND b.bettype in(4,30)
			AND b.betteam  in (SELECT convert(varchar,val) FROM dbo.strSplit(case when @betteam430 = 'All' then betteam else @betteam430 end,'^'))  
	    	--AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
    			
		 
	
	INSERT INTO #SpecialDeleteBets
	SELECT  
		b.transid,
		b.transid AS SubTransID,
		b.refno,
		b.custid, 
		b.username,
		b.odds,   
		b.modds,      
		b.OddsType,    
		b.transdate,  
		b.bettype,  
		b.betteam,  
		b.hdp1,  
		b.hdp2,  
		b.livehomescore,  
		b.liveawayscore,  
		b.Actual_stake,
		b.stake, 
		b.CurrencyName,   	
		CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
			 ELSE b.status 
			 END as status,		
		--ISNULL(SecAcceptFlag,0) SecAcceptFlag,
		m.HomeId, 
		m.AwayId, 
		m.SportType,
		m.LeagueId
	FROM bettrans b with (NOLOCK)	
		INNER JOIN Match m WITH (NOLOCK) ON b.MatchId = m.MatchId 
		INNER JOIN dbo.strSplit(@bettypes,'^') AS fb ON b.bettype=fb.val
	WHERE	b.matchid=@matchid   
		AND b.transdate>=@KickOffDate
		AND b.statusID NOT IN (101,102)
		AND b.liveindicator=0
		AND CASE
				WHEN b.bettype in (1,3,7,8,2,12) THEN CASE WHEN @betteam1378 = 'ALL' THEN betteam ELSE @betteam1378 END  
				WHEN b.bettype in (5,15) THEN CASE WHEN @betteam515 = 'ALL' THEN betteam ELSE @betteam515 END    
				ELSE betteam
			END = betteam
		AND CASE WHEN b.bettype in (1,3,7,8) THEN CASE   
				 WHEN @hdp = 9999 THEN 1  
				 WHEN @hdp = (hdp1 + hdp2) THEN 1  
				 ELSE 0   
				END  
		ELSE 1 END = 1  
		AND b.bettype NOT IN(4,6,14,16,30)
		AND b.betfrom <>'P'
		--AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END

	UNION ALL  

	SELECT  
		b.transid,
		b.transid AS SubTransID,
		b.refno,
		b.custid,   
		b.username,
		b.odds, 
		b.modds,        
		b.OddsType,    
		b.transdate,  
		b.bettype,  
		b.betteam,  
		b.hdp1,  
		hdp2,  
		b.livehomescore,  
		b.liveawayscore, 		
		b.Actual_stake,
		b.stake,  
		b.CurrencyName,   		
		CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
			 ELSE b.status 
			 END as status,  	
        --ISNULL(SecAcceptFlag,0) SecAcceptFlag,
		m.HomeId, 
		m.AwayId, 
		m.SportType,
		m.LeagueId	  
	FROM dbo.bettrans b with (NOLOCK)  		
		INNER JOIN Match m WITH (NOLOCK) ON b.MatchId = m.MatchId 
	WHERE b.matchid=@matchid   
		AND b.transdate>=@KickOffDate		
		AND b.statusID NOT IN (101,102)
		AND b.liveindicator=0				
		AND b.betfrom <>'P'		
		AND(
			(b.bettype = 6 
			AND b.betteam  in (SELECT convert(varchar,val) FROM dbo.strSplit(case when @betteam6 = 'All' then betteam else @betteam6 end,'^'))  
			)			
			OR
			(b.bettype = 16
			AND b.betteam  in (SELECT convert(varchar,val) FROM dbo.strSplit(case when @betteam16 = 'All' then betteam else @betteam16 end,'^'))  
			)
		)
        --AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END		
	UNION ALL  

	SELECT  
		b.transid,
		b.transid AS SubTransID,
		b.refno,
		b.custid,  
		b.username, 
		b.odds,  
		b.modds,       
		b.OddsType,    
		b.transdate,  
		b.bettype,  
		b.betteam,  
		b.hdp1,  
		hdp2,  
		b.livehomescore,  
		b.liveawayscore, 	
		b.Actual_stake,
		b.stake,  
		b.CurrencyName,   
		CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
			 ELSE b.status 
			 END as status,		
		--ISNULL(SecAcceptFlag,0) SecAcceptFlag,
		m.HomeId, 
		m.AwayId, 
		m.SportType,
		m.LeagueId  
	FROM dbo.bettrans b with (NOLOCK)  		
		INNER JOIN Match m WITH (NOLOCK) ON b.MatchId = m.MatchId 
		LEFT JOIN dbo.strSplit(@betteam14,'^') AS goal ON goal.val=b.betteam--dbo.Acc_SplitIndex(b.betteam,':',2)			
	WHERE b.matchid=@matchid
		AND b.transdate>=@KickOffDate		
		AND b.statusID NOT IN (101,102)
		AND b.liveindicator=0				
		AND b.betfrom <>'P'		
		AND (@betteam14='All' OR goal.val IS NOT NULL)
        --AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END		
	
	---get sub ticket of a mix parlay	
	CREATE TABLE #Currency (transid bigint,Refno bigint, CurrencyName tinyint,oddstype tinyint, bettype smallint, username NVARCHAR(50), modds smallmoney, Actual_stake MONEY, stake MONEY)
	IF EXISTS (SELECT 1 FROM dbo.strSplit(@bettypes,'^') WHERE val IN (9,29))
		AND EXISTS (SELECT 1 FROM dbo.bettransm AS b WITH(NOLOCK) 
					WHERE b.matchid=@matchid  AND b.transdate>=@KickOffDate 
						AND b.statusID NOT IN(101,102) 
						AND b.liveindicator=0 
						AND betfrom <>'P' )
						
	BEGIN		
		INSERT INTO #Currency
		SELECT transid,Refno,CurrencyName,oddstype, b2.bettype, b2.username,b2.modds, b2.Actual_stake, b2.stake
		FROM dbo.bettrans AS b2 WITH(NOLOCK)
			 INNER JOIN dbo.strSplit(@bettypes,'^') AS fb ON b2.bettype=fb.val
		WHERE b2.matchid IN (9,29)
			AND b2.bettype IN (9,29)
			AND (b2.betid IS NULL OR b2.betid = 0)
			AND liveindicator=0
			AND transdate>=@KickOffDate	
			AND statusID NOT IN (101,102)
			--AND CASE when @SAFilter = 2 then 0 else 1 END = 1
	
	
		INSERT INTO #SpecialDeleteBetms 	
		SELECT  
			cy.transid,
			b.transid AS SubTransID,			
			b.refno,
			b.custid,    
			cy.username,
			b.odds,     
			cy.modds,    
			cy.OddsType,    
			b.transdate,  
			b.bettype,  
			b.betteam,  
			b.hdp1,  
			b.hdp2,  
			b.livehomescore,  
			b.liveawayscore,    
			cy.Actual_stake,
			cy.stake,
			cy.currencyName, 		
			b.status,	
			m.HomeId, 
			m.AwayId, 
			m.SportType,
			m.LeagueId,  		
			cy.bettype as parlaytype 
		FROM dbo.bettransm b with (NOLOCK)		
			INNER JOIN Match M WITH (NOLOCK) ON M.MatchId = B.MatchId		
			INNER JOIN #Currency AS cy WITH(NOLOCK) ON cy.refno= b.refno			
		WHERE	b.matchid=@matchid
			AND b.transdate>=@KickOffDate				 
			AND b.statusID NOT IN (101,102)	  
			AND b.liveindicator=0			
			AND b.betfrom <>'P'		
			---AND CASE when @SAFilter = 2 then 0 else 1 END = 1
		
	END 

	--SINGLE TICKET SECTION	
	SELECT s.*, 0 as parlaytype, IsMP=0
	FROM #SpecialDeleteBets AS s with (NOLOCK)	
		
	UNION ALL 
	 
	SELECT s.*,IsMP=1
	FROM #SpecialDeleteBetms AS s with (NOLOCK)
	ORDER BY IsMP, transid


	DROP TABLE #SpecialDeleteBets
	DROP TABLE #SpecialDeleteBetms
	DROP TABLE #Currency
	
	SET NOCOUNT OFF
END



GO
GRANT EXECUTE ON [dbo].[Acc_BettransSelSpecialDel_EarlyKO] TO [aplweb]
GO
