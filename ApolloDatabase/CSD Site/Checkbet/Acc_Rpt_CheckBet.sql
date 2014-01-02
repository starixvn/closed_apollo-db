USE [bk]
GO
/****** Object:  StoredProcedure [dbo].[Acc_Rpt_CheckBet]    Script Date: 11/28/2013 2:57:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Acc_Rpt_CheckBet]
	@winlostdate datetime
as 
/*	
	Created by: Sophia
	Date: 20131128
	Task: Check the difference between data backup and current data of ticket 
	DB: SVRBET/BK
	Revisions:
		 
	Param's explanation:		

	
*/
BEGIN
	SET NOCOUNT ON 	
	DECLARE @CheckNormalBet int, @CheckRejectBet int
	
	SELECT		@CheckNormalBet = count(1)
	FROM		RepDB.dbo.bettrans bt WITH (NOLOCK) 
	INNER JOIN	dbo.bets b WITH (NOLOCK) 
			ON	bt.transid=b.transid		
	WHERE		bt.winlostdate=@winlostdate
				AND bt.currency <> 20
				AND (bt.bettype < 31  or bt.bettype between 121 AND 999 or bt.bettype between 1301 AND 1334 ) --sportbook 					 
				AND ((bt.stake <> b.stake) 
					or (bt.tpositiontaking <> b.tpositiontaking)
					or (bt.odds <> b.odds)
					or (bt.betteam <> b.betteam )
					or (bt.matchid <> b.matchid and bt.bettype = 10)				 
					)
				AND bt.TransId NOT IN ( SELECT	DISTINCT TransID 
										FROM	RepDB.dbo.Bettrans_Agent ba WITH (NOLOCK)
										WHERE	ba.winlostdate=@winlostdate
												AND ba.currency <> 20
												AND (ba.bettype < 31  or ba.bettype between 121 AND 999 or ba.bettype between 1301 AND 1334 ) --sportbook 					 
												AND ba.AgentID = 53288 -----line test Suntest
										) 

		
	SELECT		@CheckRejectBet = count(1)
	FROM		RepDB.dbo.bettrans bt WITH (NOLOCK) 
	INNER JOIN	dbo.betsreject b WITH (NOLOCK) ON bt.transid=b.transid
	WHERE		bt.winlostdate=@winlostdate 				
				AND bt.status <> b.status
				AND bt.currency <> 20
				AND (bt.bettype < 31  or bt.bettype between 121 AND 999 or bt.bettype between 1301 AND 1334 ) --sportbook 
				AND bt.TransId NOT IN ( SELECT	DISTINCT TransID 
										FROM	RepDB.dbo.Bettrans_Agent ba WITH (NOLOCK)
										WHERE	ba.winlostdate=@winlostdate
												AND ba.currency <> 20
												AND (ba.bettype < 31  or ba.bettype between 121 AND 999 or ba.bettype between 1301 AND 1334 ) --sportbook 					 
												AND ba.AgentID = 53288 -----line test Suntest
										) 

	SELECT @CheckNormalBet as CheckNormalBet, @CheckRejectBet as CheckRejectBet 	

END

GO  
GRANT EXECUTE ON [dbo].[Acc_Rpt_CheckBet] TO [aplweb]
GO   
  