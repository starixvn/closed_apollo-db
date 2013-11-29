ALTER PROCEDURE [dbo].[Task_Bets_Trans]
	@transid bigint

AS
/*	
	Created by: Sophia
	Date: 20131128
	Task: Gen data running
	DB: SVRBET/BK
	Revisions:
		 
	Param's explanation:		

	
*/

SET NOCOUNT ON 
INSERT INTO bets  (
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
					winlostdate,
					transdate 
					)
 
SELECT				B.transid,
					B.hdp1,
					B.hdp2,
					B.odds,
					B.stake,
					B.status,
					B.livehomescore,
					B.liveawayscore,
					B.liveindicator,
					B.betteam,
					B.tpositiontaking,
					B.matchid,
					B.oddsid,
					B.ruben,
					B.bettype,
					B.currency,
					B.custid,
					B.winlostdate,					
					B.transdate  
FROM	RepDB.dbo.BetTrans B WITH (NOLOCK) 
WHERE	B.transid > @transid   
		AND (B.bettype < 31 OR B.bettype between 121 and 999 OR B.bettype between 1301 and 1334 ) 	
		