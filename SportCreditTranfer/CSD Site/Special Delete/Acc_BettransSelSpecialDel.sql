ALTER PROCEDURE [dbo].[Acc_BettransSelSpecialDel]
	@MatchID int,
	@FromRefNo bigint,
	@ToRefNo bigint,	
	@hdp smallmoney = 9999,
	@liveindicator int = 0,
	@livehomescore smallint = NULL,
    @liveawayscore smallint = NULL,
	@FromTransdate Datetime = NULL,
	@ToTransdate Datetime = NULL,
	@bettypes varchar(128) = '',	
	@betteam1378 varchar(10) = 'ALL',
	@betteam515 varchar(10) = 'ALL',
	@betteam430 varchar(120) = '',
	@betteam6 varchar(120) = '',
	@betteam14 varchar(120) = '',
	@betteam16 varchar(120) = '',
	@UserName nvarchar(50) = '',
    @SAFilter tinyint = 0 	
AS
BEGIN
/*
    Created by: Sophia
	Date: 20130311
	Original:  
	Task: Select bets transaction need to delete
	DB: SVRCSD.RepDB

	Revisions:		
	- 20130725@Sophia: Change Username nvarchar(50)
	- 20131022@Sophia: Get CurrencyName not user currency
	- 20140811@Sophia: Add 2 new bettypes 1HT Total goal,1HT FGLG (126,127)
		
	Explanation's Param:
	@SAFilter: 
	  + 0: All tickets
	  + 1: Normal tickets only
	  + 2: SA tickets only
 
	@liveindicator:
	 + 0: Dead
	 + 1: Live
	 + 2: All
	
	@BetTeam430: bettype =4: Correct Score ; bettype =30: 1st Correct Score
	@BetTeam6: bettype=6: Total Goal; bettype = 126: 1st Total Goal
	@BetTeam14: bettype=14: First Goal/Last Goal; bettype = 127: 1st First Goal/ Last Goal
	@BetTeam16: bettype=16: Half Time/Full Time

	EX: exec Acc_BettransSelSpecialDel @bettypes='1^2^3^4^5^6^7^8^12^13^14^15^16^20^21^24^25^26^27^28^30^121^122^123^124^125^126^127^133^134^135^140^141^142^145^146^147^148^149^1',@betteam6='0-1^2-3^4-6^7-over',@livehomescore=NULL,@liveawayscore=NULL,@betteam515='1',@liveindicator=2,@ToTransdate=NULL,@ToRefNo=1000065397,@hdp=0.5000,@FromTransdate=NULL,@SAFilter=0,@betteam14='1:1^1:2^2:1^2:2^0:0',@FromRefNo=1000065331,@betteam16='1:1^1:0^1:2^0:1^0:0^0:2^2:1^2:0^2:2',@betteam430='1:0^2:0^2:1^3:0^3:1^3:2^4:0^4:1^4:2^4:3^5:0^0:0^1:1^2:2^3:3^4:4^0:1^0:2^1:2^0:3^1:3^2:3^0:4^1:4^2:4^3:4^0:5',@betteam1378='h',@MatchID=9441341,@UserName=N'sa'

*/
	SET NOCOUNT ON
	CREATE TABLE #SpecialDeleteBets (transid bigint,CustId int,username nvarchar(50),odds smallmoney, OddsType int, 
									 transdate datetime, bettype smallint, betteam nvarchar(10),hdp1 smallmoney, hdp2 smallmoney,
									 Liveindicator bit, livehomescore smallint, liveawayscore smallint, Stake money,CurrencyName varchar(50),
									 status nvarchar(10), SecAcceptFlag bit,  HomeId Int, AwayId int, SportType smallint, LeagueId int)

	IF exists( SELECT convert(int,val) FROM dbo.strSplit(@bettypes,'^') Where convert(int,val) in (4,30) )
		insert into #SpecialDeleteBets
		select
			b.transid,
			b.CustId,
			b.username,
			b.odds,   
			b.OddsType,  
			b.transdate,
			b.bettype,
			betteam,
			hdp1,
			hdp2,
			b.Liveindicator,
			b.livehomescore,
			b.liveawayscore,
			stake as Stake,
			b.CurrencyName, 
				CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
				 ELSE b.status 
				 END as status,
			ISNULL(SecAcceptFlag,0) SecAcceptFlag,
			m.HomeId, 
			m.AwayId, 
			m.SportType,
			m.LeagueId
		FROM bettrans b WITH (NOLOCK)
			INNER JOIN Match m WITH (NOLOCK) ON b.MatchId = m.MatchId
			INNER JOIN dbo.strSplit(@BetTypes,'^') s ON s.val = b.bettype
		WHERE
			b.matchid=@matchid 
			and b.transid between @FromRefNo and @ToRefNo 	
			AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
			AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
			AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END
			AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
							AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 			
			and statusID NOT IN (101,102 )
			and b.bettype in (4,30)
			and b.betteam in (SELECT convert(varchar,val) FROM dbo.strSplit(case when @betteam430 = 'All' then betteam else @betteam430 end,'^'))
    		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
			
  

	insert into #SpecialDeleteBets
	select
		b.transid,
		b.CustId,
		b.username,
		b.odds,   
		b.OddsType,  
		b.transdate,
		b.bettype,
		betteam,
		hdp1,
		hdp2,
		b.Liveindicator,
		b.livehomescore,
		b.liveawayscore,
		stake as Stake,
		b.CurrencyName, 
		CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
			 ELSE b.status 
			 END as status,
		ISNULL(SecAcceptFlag,0) SecAcceptFlag,
		m.HomeId, 
		m.AwayId, 
		m.SportType,
		m.LeagueId
		FROM bettrans b WITH (NOLOCK)
			INNER JOIN Match m WITH (NOLOCK) ON b.MatchId = m.MatchId 
			INNER JOIN dbo.strSplit(@BetTypes,'^') s ON s.val = b.bettype
		WHERE  b.MatchId = @matchid
				and b.transid between @FromRefNo and @ToRefNo 					
				--and status NOT IN ('Void', 'Reject')
				and statusID NOT IN (101,102)

				AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
				AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
				AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END
				AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
								AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 
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
				AND b.bettype NOT IN(4,6,14,16,30,126,127)
				AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END

	UNION ALL

	select
		b.transid,
		b.CustId,
		b.username,
		b.odds,   
		b.OddsType,  
		b.transdate,
		b.bettype,
		betteam,
		hdp1,
		hdp2,
		b.Liveindicator,
		b.livehomescore,
		b.liveawayscore,
		stake as Stake,
		b.CurrencyName, 
		CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
			 ELSE b.status 
			 END as status,
		ISNULL(SecAcceptFlag,0) SecAcceptFlag,
		m.HomeId, 
		m.AwayId, 
		m.SportType,
		m.LeagueId
		FROM bettrans b WITH (NOLOCK)
			INNER JOIN Match m WITH (NOLOCK) ON b.MatchId = m.MatchId 
			INNER JOIN dbo.strSplit(@BetTypes,'^') s ON s.val = b.bettype
		WHERE	b.MatchId = @matchid
				AND b.transid between @FromRefNo and @ToRefNo 			 
				AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
				AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
				AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END
				AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
								AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 
				--and status NOT IN ('Void', 'Reject')
				AND statusID NOT IN (101,102)				
				AND(
					(b.bettype IN (6,126)
					AND b.betteam  in (SELECT convert(varchar,val) FROM dbo.strSplit(case when @betteam6 = 'All' then betteam else @betteam6 end,'^'))  
					)			
					OR
					(b.bettype = 16
					AND b.betteam  in (SELECT convert(varchar,val) FROM dbo.strSplit(case when @betteam16 = 'All' then betteam else @betteam16 end,'^'))  
					)
				)
				AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		
	
	UNION ALL 
	
	select
		b.transid,
		b.CustId,
		b.username,
		b.odds,   
		b.OddsType,  
		b.transdate,
		b.bettype,
		betteam,
		hdp1,
		hdp2,
		b.Liveindicator,
		b.livehomescore,
		b.liveawayscore,
		stake as Stake,
		b.CurrencyName, 
		CASE WHEN b.status = 'running' AND IsNull(b.SecAcceptFlag, 0) = 1 and IsNull(b.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
			 ELSE b.status 
			 END as status,		
		ISNULL(SecAcceptFlag,0) SecAcceptFlag,
		m.HomeId, 
		m.AwayId, 
		m.SportType,
		m.LeagueId
	FROM bettrans b WITH (NOLOCK)
		INNER JOIN Match m WITH (NOLOCK) ON b.MatchId = m.MatchId 
		INNER JOIN dbo.strSplit(@BetTypes,'^') s ON s.val = b.bettype
		LEFT JOIN dbo.strSplit(@betteam14,'^') AS goal ON goal.val=b.betteam--dbo.Acc_SplitIndex(b.betteam,':',2)			
	WHERE
		b.matchid=@matchid 
		and b.transid between @FromRefNo and @ToRefNo 			 
		AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 
		--and status NOT IN ('Void', 'Reject')
		and b.statusID NOT IN (101,102)
		AND b.bettype IN (14,127)
		AND (@betteam14='All' OR goal.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		
 


	SELECT * FROM #SpecialDeleteBets with (NOLOCK)
	ORDER BY transid


	DROP TABLE #SpecialDeleteBets
	
	SET NOCOUNT OFF
/*
*/
END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransSelSpecialDel] TO [aplweb] AS [dbo]
GO 