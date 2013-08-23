ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Sporttype]
	@winlostdate	DATE

AS
/*	Creator: Sophia
	Date: 20130813
	Task: Daily Winloss Report (2h)
	DB: SVRCSD.RepDB
		
	Revision:
		 
	Explanation's Param:
		

*/
BEGIN
	SET NOCOUNT ON


	CREATE TABLE #TempBettrans(	
						matchid INT, 
						bettype INT, 
						winlost MONEY, 
						Share MONEY, 
						commission MONEY,  
						Linetotal MONEY,
						turnover MONEY
						)
					
	---------------------------------------------------------------------------------------

	--Declare @temp table to contain all matches based on @winlostdate
	DECLARE @Match TABLE (matchid INT, sporttype smallint, type varchar(10), primary key(matchid, type))
	INSERT INTO @Match 
	SELECT	m.matchid, 
			l.sporttype,
			m.type
	FROM (
			SELECT matchid, leagueid, 'match' as type FROM match WITH (NOLOCK) WHERE eventdate = @winlostdate
			UNION ALL
			SELECT orid, leagueid, 'outright' as type FROM outright WITH (NOLOCK) WHERE eventdate = @winlostdate
			)m	
	INNER JOIN league l WITH (NOLOCK) ON m.leagueid = l.leagueid	 

	--------------------------------------------------------------------------------
	INSERT INTO #TempBettrans
	SELECT	matchid, bettype, 
			SUM((winlost-actual_stake)*actualrate) as winlost,
			SUM(TWinLost*actualrate) Share,
			SUM(TComm*actualrate) commission,
			SUM((winlost-actual_stake+Twinlost+TComm)*actualrate) LineTotal,
			SUM((1-TPositionTaking)*ABS(stake)*actualrate) turnover 
	FROM bettrans b WITH(NOLOCK)
	WHERE winlostdate = @winlostdate
		AND bettype < 19001
		AND b.statusID NOT IN (0, 1, 102, 101, 103)   ----- Void, reiject, refund
	GROUP BY matchid, bettype 
	
	--------------------------------------------------------------------------------
	-- GET DATA
	SELECT	case when m.sporttype> 1 THEN 2 ELSE 1 end as DisplayOrder,
			case when m.sporttype> 1 then 'Other Sports' else 'Soccer' end as SportName,
			SUM(winLost) AS winlost,
			SUM(Share) AS Share,
			sum(commission) AS Commission,	
			SUM(LineTotal) AS LineTotal,
			SUM(turnover) AS Turnover 
	FROM	#TempBettrans b WITH(NOLOCK)
		INNER JOIN @Match m on b.matchid = m.matchid
	WHERE	(b.bettype < 31 
				OR b.bettype BETWEEN 121 AND 999
				OR bettype BETWEEN 1301 and 1334)	
			AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END  
	GROUP BY		
			case when m.sporttype> 1 THEN 2 ELSE 1 end,
			case when m.sporttype> 1 then 'Other Sports' else 'Soccer' end
				

	UNION 
	SELECT  3,'Mix Parlay',
			SUM(winlost) WinLost,
			SUM(Share) Share,
			SUM(commission) Commission,	
			SUM(LineTotal) AS LineTotal,
			SUM(turnover) Turnover 
	FROM	#TempBettrans b WITH (NOLOCK)
	WHERE	bettype = 9 
			AND matchid = 9
	GROUP BY Bettype
					 
	UNION 
	SELECT  4,'System Parlay',
			SUM(winlost) WinLost,
			SUM(Share) Share,
			SUM(commission) Commission,	
			SUM(LineTotal) AS LineTotal,
			SUM(turnover) Turnover 
	FROM	#TempBettrans AS b WITH (NOLOCK)
	WHERE	bettype = 29 
			AND matchid = 29
	GROUP BY Bettype			

				 
	ORDER BY DisplayOrder
					
	DROP TABLE #TempBettrans
END



GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_Sporttype] TO [aplweb]