CREATE PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Details14]
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
			 
	*/	

	SET NOCOUNT ON
	
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
					isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral
			FROM 	bettrans14 b with (nolock)
					INNER JOIN match14 m with (nolock) ON b.matchid = m.matchid
			WHERE
					b.winlostdate = @winlostdate
					AND b.BetType = @Bettype	
					AND b.liveindicator = @liveindicator						
					AND b.statusID NOT IN (0, 1, 102, 101, 103) 		
					AND m.SportType = @SportType			
						
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
				0 liveindicator,
				b.BetType, 
				l.leagueid,
				CONVERT(MONEY,sum((winlost-actual_stake)*actualrate)) WinLost,
				CONVERT(MONEY,sum((TWinlost)*actualrate)) Share,
				CONVERT(MONEY,sum(TComm*actualrate)) Commission,
				CONVERT(MONEY,sum((winlost-actual_stake+TWinlost+TComm)*actualrate)) LineTotal,
				CONVERT(MONEY,sum((1-tpositiontaking)*ABS(b.stake)*actualrate)) Turnover,
				CONVERT(BIT,0) as IsNeutral
		FROM
				bettrans14 b with (nolock)
				INNER JOIN outright14 o with (nolock) ON b.matchid = o.orid
				INNER JOIN league l with (nolock) ON o.leagueid = l.leagueid
		WHERE	b.winlostdate = @winlostdate
				AND b.bettype = 10
				AND b.statusID NOT IN (0, 1, 102, 101, 103) 							
				AND l.SportType = @SportType
				
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
GRANT EXECUTE ON dbo.[Acc_Rpt_DailyWLDirect_Details14] TO [aplweb]
GO