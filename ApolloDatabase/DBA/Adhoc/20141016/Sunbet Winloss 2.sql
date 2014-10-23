--RepDB:

DECLARE @fromDate datetime, @todate datetime

select @fromDate = '2014-1-1', @todate = '2014-10-5'

select agentid
into #TestAgents
from AgentInfo (nolock)
WHERE AgentLevel=1 and Username <> 'pal'

select winlostdate [Date], 
	case when bettype = 9 then
		CASE WHEN b.livehomescore = 0 THEN 'Non-Live' WHEN b.livehomescore = 1 THEN 'Live' WHEN b.livehomescore = 2 THEN 'Mix Live and Non-Live' END
	else
		case when LiveIndicator = 0 then 'Non-Live' else 'Live' end
	end [Live Status],
	-SUM((winlost-actual_stake+Twinlost+TComm)*actualrate) [Winloss Sunbet],
	SUM((1-tpositiontaking)*CASE WHEN B.StatusID IN (112,113) AND (ABS(B.MOdds) <> 0.25 OR B.Bettype IN (9,29,10)) THEN ABS(B.Stake) 
      ELSE CASE WHEN B.StatusID IN (112,113) AND ABS(B.MOdds) =0.25 AND B.Bettype NOT IN (9,29,10) THEN  ABS(B.Stake)*0.5 ELSE 0 END END*actualrate) [Turnover Sunbet]
from ArchiveDB.dbo.bettrans_bk b with (nolock)
where winlostdate between @fromDate AND @toDate
	AND bettype < 19001
	AND b.statusID NOT IN (0, 1)   ----- Void, reiject, refund
	AND b.TransID NOT IN 
	(
		SELECT	TransID FROM ArchiveDB.dbo.Bettrans_Agent_bk WITH (NOLOCK)
		WHERE	winlostdate between @fromDate AND @toDate 
			AND statusID not in (0,1) --('VOID','REJECT','REFUND')
			AND bettype < 19001 and bettype <> 9
			AND AgentID IN(select agentID from #TestAgents)
	)  
group by winlostdate,
	case when bettype = 9 then
		CASE WHEN b.livehomescore = 0 THEN 'Non-Live' WHEN b.livehomescore = 1 THEN 'Live' WHEN b.livehomescore = 2 THEN 'Mix Live and Non-Live' END
	else
		case when LiveIndicator = 0 then 'Non-Live' else 'Live' end
	end
union all
select winlostdate [Date], 
	case when bettype = 9 then
		CASE WHEN b.livehomescore = 0 THEN 'Non-Live' WHEN b.livehomescore = 1 THEN 'Live' WHEN b.livehomescore = 2 THEN 'Mix Live and Non-Live' END
	else
		case when LiveIndicator = 0 then 'Non-Live' else 'Live' end
	end [Live Status],
	-SUM((winlost-actual_stake+Twinlost+TComm)*actualrate) [Winloss Sunbet],
	SUM((1-tpositiontaking)*CASE WHEN B.StatusID IN (112,113) AND (ABS(B.MOdds) <> 0.25 OR B.Bettype IN (9,29,10)) THEN ABS(B.Stake) 
      ELSE CASE WHEN B.StatusID IN (112,113) AND ABS(B.MOdds) =0.25 AND B.Bettype NOT IN (9,29,10) THEN  ABS(B.Stake)*0.5 ELSE 0 END END*actualrate) [Turnover Sunbet]
from dbo.bettrans14 b with (nolock)
where winlostdate between @fromDate AND @toDate
	AND bettype < 19001
	AND b.statusID NOT IN (0, 1)   ----- Void, reiject, refund
	AND b.TransID NOT IN 
	(
		SELECT	TransID FROM dbo.Bettrans14_Agent WITH (NOLOCK)
		WHERE	winlostdate between @fromDate AND @toDate 
			AND statusID not in (0,1) --('VOID','REJECT','REFUND')
			AND bettype < 19001 and bettype <> 9
			AND AgentID IN(select agentID from #TestAgents)
	)  
group by winlostdate,
	case when bettype = 9 then
		CASE WHEN b.livehomescore = 0 THEN 'Non-Live' WHEN b.livehomescore = 1 THEN 'Live' WHEN b.livehomescore = 2 THEN 'Mix Live and Non-Live' END
	else
		case when LiveIndicator = 0 then 'Non-Live' else 'Live' end
	end
order by [Date]

DROP TABLE #TestAgents

