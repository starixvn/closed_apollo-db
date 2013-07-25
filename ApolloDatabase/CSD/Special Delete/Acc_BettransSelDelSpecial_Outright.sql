ALTER PROCEDURE [dbo].[Acc_BettransSelDelSpecial_Outright]
	@OutrightID int = 0,
	@FromRefNo bigint,
	@ToRefNo bigint,
	@UserName nvarchar(50) = ''
AS
SET NOCOUNT ON

/*
Created by:  Sophia
Date: 20130307
Original: 
Task: Select bets transaction need to delete
DB: SVRCSD.RepDB

Revisions:
	  - 20130725@Sophia: Change username nvarchar(50)
	
Explanation's Param:

*/

CREATE TABLE #OutrightDeleteBets (transid bigint,custid int,username nvarchar(50),odds smallmoney,transdate datetime, Stake money,currency nvarchar(50),status nvarchar(10))

INSERT INTO #OutrightDeleteBets
select
	b.transid,
	b.CustId, 
	b.username,
	b.odds,
	b.transdate,	
	b.stake,
	b.currency, 
	b.status 
from 
	bettrans b with (NOLOCK)
	INNER JOIN outright o with(NOLOCK) ON b.matchid = o.orid
where
	b.bettype = 10
	--and b.status NOT IN('Void', 'Reject')
	and b.statusID NOT IN (101,102)
	and b.transid between @FromRefNo and @ToRefNo 
	and o.orid = case when @OutrightID = 0 then o.orid else @OutrightID end 
order by transid


SELECT * FROM #OutrightDeleteBets WITH (NOLOCK)
ORDER BY transid

DROP TABLE #OutrightDeleteBets




GO
GRANT EXECUTE ON [dbo].[Acc_BettransSelDelSpecial_Outright] TO [aplweb]

GO
--GRANT VIEW DEFINITION ON [dbo].[Acc_BettransSelDelSpecial_Outright] TO [VNTeam]