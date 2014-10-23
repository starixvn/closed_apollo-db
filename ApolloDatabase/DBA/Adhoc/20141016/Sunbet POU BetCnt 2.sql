--SVARC.RepDB

declare @from datetime, @to datetime

select @from = '2014-1-1', @to = '2014-10-5'

--get daily highest 10min's total users
select DATEADD(dd, DATEDIFF(dd, 0, logdate), 0) logdate, max(Users) MaxUsers into #PeakOnline
from SVRPRO.OnlineDB.dbo.TotalOnline_bk with (nolock)
where DATEADD(dd, DATEDIFF(dd, 0, logdate), 0) between @from and @to and serverID = 0
group by DATEADD(dd, DATEDIFF(dd, 0, logdate), 0)

insert into #PeakOnline
select DATEADD(dd, DATEDIFF(dd, 0, logdate), 0) logdate, max(Users) MaxUsers
from SVRPRO.OnlineDB.dbo.TotalOnline with (nolock)
where DATEADD(dd, DATEDIFF(dd, 0, logdate), 0) between @from and @to and serverID = 0
group by DATEADD(dd, DATEDIFF(dd, 0, logdate), 0)

--merge result with bet count
select winlostdate [Date], count(1) [No Of Tickets], MaxUsers [Peak Online Users]
from dbo.BetTrans14 b with (nolock)
	inner join #PeakOnline o on b.WinLostDate = o.logdate
where winlostdate between @from and @to
	AND b.statusID NOT IN (0,1,102,101,103)
	AND b.TransID NOT IN 
	(
		SELECT	TransID FROM dbo.BetTrans14_Agent WITH (NOLOCK)
		WHERE	winlostdate between @from and @to
			AND statusID not in (0,1,101,102,103) --('VOID','REJECT','REFUND')
			AND AgentID = 53288 -----line test Suntest
	) 
	AND b.currency <> 20
group by winlostdate, MaxUsers
union all
select winlostdate [Date], count(1) [No Of Tickets], MaxUsers [Peak Online Users]
from ArchiveDB.dbo.BetTrans_bk b with (nolock)
	inner join #PeakOnline o on b.WinLostDate = o.logdate
where winlostdate between @from and @to
	AND b.statusID NOT IN (0,1,102,101,103)
	AND b.TransID NOT IN 
	(
		SELECT	TransID FROM ArchiveDB.dbo.BetTrans_Agent_bk WITH (NOLOCK)
		WHERE	winlostdate between @from and @to
			AND statusID not in (0,1,101,102,103) --('VOID','REJECT','REFUND')
			AND AgentID = 53288 -----line test Suntest
	) 
	AND b.currency <> 20
group by winlostdate, MaxUsers
order by [Date]

drop table #PeakOnline