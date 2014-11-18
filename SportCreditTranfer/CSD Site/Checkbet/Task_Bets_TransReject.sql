 
ALTER PROCEDURE [dbo].[Task_Bets_TransReject]
	@transid bigint
AS 
/*	
	Created by: Sophia
	Date: 20131128
	Task: Gen data reject /refund
	DB: SVRBET/BK
	Revisions:
		 
	Param's explanation:		

	
*/
INSERT INTO BetsReject (
						transid,
						hdp1,
						hdp2,
						odds,
						stake,
						status,
						livehomescore,
						liveawayscore,
						liveindicator,
						betteam,
						tpositiontaking,
						matchid,
						oddsid,
						ruben,
						bettype,
						currency,
						custid,
						winlostdate
						)
SELECT 					transid,
						hdp1,
						hdp2,
						odds,
						stake,
						status,
						livehomescore,
						liveawayscore,
						liveindicator,
						betteam,
						tpositiontaking,
						matchid,
						oddsid,
						ruben,
						bettype,
						currency,
						custid,
						winlostdate
FROM	RepDB.dbo.BetTrans B WITH (NOLOCK)
WHERE	B.transid > @transid  
		AND (B.bettype < 31 OR B.bettype between 121 and 999 OR B.bettype between 1301 and 1334 ) 	
		and B.statusID in (101, 102)  ----reject','void'
	 