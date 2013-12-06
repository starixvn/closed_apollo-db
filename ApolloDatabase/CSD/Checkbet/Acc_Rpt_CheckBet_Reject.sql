ALTER PROCEDURE [dbo].[Acc_Rpt_CheckBet_Reject]
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
    SELECT bt.transid
    FROM REPDB.dbo.bettrans bt WITH (nolock) 
        INNER join dbo.betsReject b WITH (nolock) ON bt.transid=b.transid        
    WHERE bt.winlostdate=@winlostdate
      	and (bt.status <> b.status) 
		and b.currency <> 20
		and (bt.bettype < 31  or bt.bettype between 121 AND 999 or bt.bettype between 1301 AND 1334 )--sportbook
		AND bt.TransId NOT IN (		SELECT	DISTINCT TransID 
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
	SELECT	orid,
			0 as homeid,
			teamid as awayid,
			matchcode,
			'outright' as type
	FROM REPDB.dbo.outright with (NOLOCK) where eventdate = @winlostdate
	 
	
	--Check ticket of sport book 
	select  bt.transid, 
			bt.transdate,
			bt.CurrencyName,
			bt.bettype,
			bt.Username,
			bt.stake, 			
			bt.odds, 			
			bt.betteam, 			
			m.homeid,
			m.awayid,
			m.matchcode,
			bt.liveindicator,
			bt.hdp1,
			bt.oddstype,
			bt.tpositiontaking, 
			bt.status as NewStatus, 
			b.status as OldStatus
	FROM REPDB.dbo.bettrans bt with (NOLOCK)
		inner join dbo.betsreject b with (nolock) on bt.transid=b.transid		 
		LEFT JOIN @Match m on b.matchid = m.matchid AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END	
	WHERE  bt.transid in (SELECT transid from #tmp)			
			
	ORDER BY bt.transid		
	
	DROP TABLE #tmp	 	
END
GO  
GRANT EXECUTE ON [dbo].[Acc_Rpt_CheckBet_Reject] TO [aplweb]
GO   
  
