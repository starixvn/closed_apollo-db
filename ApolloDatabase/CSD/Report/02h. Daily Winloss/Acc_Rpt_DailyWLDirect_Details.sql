ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Details]
	@winlostdate	datetime,
	@SportType		int = 1,
	@liveindicator	bit,
	@bettype		int	
AS

	/*	Creator: Sophia
		Date: 20130816
		Task: Daily Winloss Report /by Bettype/Detail (2h)
		DB: SVRSCD.RepDB
		
		Revisions:
			 - 20130916@Sophia: add ActualTurnover, exclude line test Suntest 53288
			  
	*/	

	SET NOCOUNT ON
	
	CREATE TABLE #TestLine (TransID BIGINT)

	INSERT INTO #TestLine (TransID)
	SELECT	TransID 
	FROM	Bettrans_Agent WITH (NOLOCK)
	WHERE	winlostdate = @winlostdate			 
			AND statusID not in (0,1,101,102,103) --('VOID','REJECT','REFUND')
			AND bettype <= 19000
			AND AgentID = 53288 -----line test Suntest


	IF @bettype <> 10
	BEGIN
			SELECT
					b.matchid,
					m.matchcode,
					m.HomeId,
					m.AwayId,
					b.liveindicator,
					b.BetType, 
					m.leagueid,					
					CONVERT(MONEY,sum((winlost-actual_stake)*actualrate)) WinLost,
					CONVERT(MONEY,sum((TWinlost)*actualrate)) Share,
					CONVERT(MONEY,sum(Tcomm*actualrate)) Commission,
					CONVERT(MONEY,sum((winlost-actual_stake+TWinlost+Tcomm)*actualrate)) LineTotal,
					CONVERT(MONEY,sum((1-tpositiontaking)*ABS(b.stake)*actualrate)) Turnover,
					CONVERT(MONEY,SUM(CASE WHEN StatusID IN (112,113) AND (ABS(MOdds) <> 0.25 OR Bettype IN (9,29,10)) THEN ABS(Stake)
										 ELSE CASE WHEN StatusID IN (112,113) AND ABS(MOdds) =0.25 AND Bettype NOT IN (9,29,10) THEN ABS(Stake)*0.5  ELSE 0 END END * (1-TPositionTaking)*actualrate)) AS ActualTurnover,
					isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral					
			FROM 	bettrans b with (nolock)
					INNER JOIN match m with (nolock) ON b.matchid = m.matchid
			WHERE
					b.winlostdate = @winlostdate
					AND b.BetType = @Bettype	
					AND b.liveindicator = @liveindicator						
					AND b.statusID NOT IN (0, 1, 102, 101, 103) 		
					AND m.SportType = @SportType			
					AND b.TransID NOT IN (SELECT TransID FROM #TestLine)
			GROUP BY
					b.matchid,
					m.matchcode,
					m.HomeId,
					m.AwayId,
					b.liveindicator,
					b.bettype, 
					m.leagueid,
					m.isNeutral
			ORDER BY 
					b.bettype, 
					m.leagueid, 
					m.matchcode, 
					m.HomeId
	END
	ELSE
	BEGIN
		SELECT
				b.matchid,
				o.matchcode,
				o.TeamId as HomeId,
				0 as AwayId,
				CONVERT(BIT, 0) as liveindicator,
				b.BetType, 
				l.leagueid,
				CONVERT(MONEY,sum((winlost-actual_stake)*actualrate)) WinLost,
				CONVERT(MONEY,sum((TWinlost)*actualrate)) Share,
				CONVERT(MONEY,sum(TComm*actualrate)) Commission,
				CONVERT(MONEY,sum((winlost-actual_stake+TWinlost+TComm)*actualrate)) LineTotal,
				CONVERT(MONEY,sum((1-tpositiontaking)*ABS(b.stake)*actualrate)) Turnover,
				CONVERT(MONEY,SUM(CASE WHEN StatusID IN (112,113) AND (ABS(MOdds) <> 0.25 OR Bettype IN (9,29,10)) THEN ABS(Stake)
										 ELSE CASE WHEN StatusID IN (112,113) AND ABS(MOdds) =0.25 AND Bettype NOT IN (9,29,10) THEN ABS(Stake)*0.5  ELSE 0 END END * (1-TPositionTaking))) AS ActualTurnover,
				CONVERT(BIT,0) as IsNeutral
		FROM
				bettrans b with (nolock)
				INNER JOIN outright o with (nolock) ON b.matchid = o.orid
				INNER JOIN league l with (nolock) ON o.leagueid = l.leagueid
		WHERE	b.winlostdate = @winlostdate
				AND b.bettype = 10
				AND b.statusID NOT IN (0, 1, 102, 101, 103) 							
				AND l.SportType = @SportType
				AND b.TransID NOT IN (SELECT TransID FROM #TestLine)
		GROUP BY
				b.matchid,
				o.matchcode,
				o.TeamId,
				b.bettype, 
				l.leagueid
		ORDER BY 
				b.bettype, 
				leagueid,
				o.matchcode, 
				HomeId
	END	


GO
GRANT EXECUTE ON dbo.[Acc_Rpt_DailyWLDirect_Details] TO [aplweb]
GO