
ALTER PROCEDURE [dbo].[Acc_Rpt_CheckBet_Normal]
	@winlostdate datetime
as 
/*	
	Created by: Sophia
	Date: 20131128
	Task: Show the difference between data backup and current data of normal ticket in detail
	DB: SVRBET/BK
	Revisions:
		 
	Param's explanation:		
	
*/
BEGIN 
	SET NOCOUNT ON 	
	CREATE TABLE #tmp(transid BIGINT)
	 
    INSERT INTO #tmp
    SELECT	bt.transid
    FROM	REPDB.dbo.bettrans bt WITH (NOLOCK) 
        INNER JOIN dbo.bets b WITH (NOLOCK) ON bt.transid=b.transid        
    WHERE	bt.winlostdate=@winlostdate
            AND bt.currency <> 20
            AND (bt.bettype < 31  or bt.bettype between 121 AND 999 or bt.bettype between 1301 AND 1334)--sportbook    
            AND ((bt.stake <> b.stake) 
				or (bt.tpositiontaking <> b.tpositiontaking)
                or (bt.odds <> b.odds )
				or (bt.betteam <> b.betteam )
				or ((bt.matchid <> b.matchid) and bt.bettype = 10)
                ) 
			AND bt.TransId NOT IN ( SELECT	DISTINCT TransID 
									FROM	RepDB.dbo.Bettrans_Agent ba WITH (NOLOCK)
									WHERE	ba.winlostdate=@winlostdate
											AND ba.currency <> 20
											AND (ba.bettype < 31  or ba.bettype between 121 AND 999 or ba.bettype between 1301 AND 1334 ) --sportbook 					 
											AND ba.AgentID = 53288 -----line test Suntest
										) 
   
                
	DECLARE @Match TABLE (matchid int, homeid int, awayid int, matchcode nvarchar(50), type varchar(10))
	
	INSERT INTO @Match
	SELECT	matchid,
			homeid,
			awayid,
			matchcode,
			'match' as type
	FROM REPDB.dbo.match with (NOLOCK) where eventdate = @winlostdate
		
	UNION ALL	
	SELECT	orid as matchid,
			0 as homeid,
			teamid as awayid,
			matchcode,
			'outright' as type
	FROM REPDB.dbo.outright with (NOLOCK) where eventdate = @winlostdate
	
 
		
	--Check ticket of sport book 
	SELECT  bt.transid, 
			bt.transdate,
			bt.CurrencyName,
			bt.bettype,
			bt.Username,
			bt.stake as NewStake, 
			b.stake as OldStake, 
			bt.odds as NewOdds,
			b.odds as OldOdds, 			
			bt.betteam as NewBetteam,
			b.betteam as OldBetteam, 
			m1.homeid,
			m1.awayid as NewAwayID,			
			CASE WHEN bt.bettype = 10 THEN m2.awayid ELSE m1.awayid END as OldAwayID,			
			m1.matchcode as NewMatchCode,		
			CASE WHEN bt.bettype = 10 THEN m2.matchcode ELSE m1.matchcode END as OldMatchCode,		
			bt.liveindicator,
			bt.hdp1,
			bt.oddstype,
			bt.tpositiontaking as NewPT, 
			b.tpositiontaking as OldPT, 
			bt.status  	
			 
	FROM REPDB.dbo.bettrans bt WITH (NOLOCK)
		INNER JOIN dbo.bets b WITH (NOLOCK) ON bt.transid = b.transid		
		LEFT JOIN @Match m1 on bt.matchid = m1.matchid AND m2.type = CASE WHEN b.bettype= 10 THEN 'outright' ELSE 'match' END 
		LEFT JOIN @Match m2 on b.matchid = m2.matchid AND m2.type = CASE WHEN b.bettype= 10 THEN 'outright' ELSE 'match' END 
	WHERE bt.transid in (SELECT transid from #tmp)		
		  
		 
 	ORDER BY bt.transid
	
	DROP TABLE #tmp
END

GO  
GRANT EXECUTE ON [dbo].[Acc_Rpt_CheckBet_Normal] TO [aplweb]
GO   
  
