ALTER  PROCEDURE [dbo].[Acc_BettransSelRecoverSpecialBets]
    @transid bigint,
    @ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(1000) = '' OUTPUT
AS
/*
Created: Sophia
Date:  20130307
Task: get data to recover bet
DB: SVRCSD.RepDB
Revisions: 
	- 20131022@Sophia: Get CurrencyName not user currency
	- 20140404@Sophia: Select temp table before return in case the TransId does not existed
	
Param's Explanation:
	- @Type: sports type
		0: Sportsbook
		
*/

SET NOCOUNT ON
BEGIN
	DECLARE @Data AS TABLE ( Refno BIGINT,
					 transid BIGINT, 
					 CustId  INT, 
					 username NVARCHAR(50) , 
					 transdate DATETIME, 
					 hdp1 SMALLMONEY, 
					 hdp2 SMALLMONEY, 
					 odds SMALLMONEY, 
					 Stake MONEY, 
					 STATUS VARCHAR(10), 
					 livehomescore SMALLINT, 
					 liveawayscore SMALLINT, 
					 bettype SMALLINT, 
					 liveindicator BIT, 
					 betteam VARCHAR(10), 
					 OddsType TINYINT, 
					 CurrencyName VARCHAR(100), 
					 betfrom VARCHAR (1),
					 HomeId INT, 
					 AwayId INT,
					 LeagueId INT,
					 SportType TINYINT)



	--- Check transid
	DECLARE @bettype smallint
	SET @bettype = 0
	
	select @bettype = bettype from bettrans with (NOLOCK) where transid = @transid
	
	IF ISNULL(@bettype,0) = 0 
		OR NOT (					
					@bettype < 31  or @bettype between 121 AND 999 --sportbook					
			    )
	BEGIN 
		SET @ErrCode = 1
		SET @ErrMsg ='Invalid TransID.'   
		SELECT * FROM @Data
		RETURN
	END
	
	IF NOT (@bettype < 31  or @bettype between 121 AND 999) 
	BEGIN
		SET @ErrCode = 2  
		SET @ErrMsg ='This TransID doesn''t belong to sportsbook.'  
		SELECT * FROM @Data
		RETURN
	END	
	
	IF @bettype = 10 
	BEGIN 
			INSERT INTO @Data ( Refno, transid, CustId, username, transdate, hdp1, hdp2, odds, Stake, STATUS, livehomescore, liveawayscore, 
								bettype, liveindicator, betteam, OddsType, CurrencyName, betfrom, HomeId, AwayId, LeagueId, SportType)
			SELECT  DISTINCT z.transid AS refno, 
					z.transid, 
					z.CustId, 
					b.username, 
					b.transdate, 
					b.hdp1, 
					b.hdp2, 
					b.odds, 
					b.stake AS Stake, 
					z.STATUS, 
					b.livehomescore, 
					b.liveawayscore, 
					b.bettype, 
					b.liveindicator, 
					b.betteam, 
					b.OddsType, 
					b.CurrencyName, 
					b.betfrom,
					m.teamId as HomeId, 
					0 as AwayId,
					m.LeagueId,
					l.SportType
			FROM zzzbettrans z WITH (NOLOCK) 
			INNER JOIN bettrans b WITH (NOLOCK) 
					ON b.CustId = z.CustId AND b.matchid = z.matchid and b.transid = z.transid
			INNER JOIN Outright m WITH (NOLOCK) 
					ON m.orid = b.matchId
			INNER JOIN League l WITH (NOLOCK)
					ON l.LeagueId = m.LeagueId
			WHERE z.transid = @transid AND b.matchid>0
			ORDER BY z.transid
	END
	ELSE
	BEGIN 
			INSERT INTO @Data ( Refno, transid, CustId, username, transdate, hdp1, hdp2, odds, Stake, STATUS, livehomescore, liveawayscore, 
								bettype, liveindicator, betteam, OddsType, CurrencyName, betfrom, HomeId, AwayId, LeagueId, SportType)
			SELECT  DISTINCT z.transid AS refno, 
					z.transid, 
					z.CustId, 
					b.username, 
					b.transdate, 
					b.hdp1, 
					b.hdp2, 
					b.odds, 
					b.stake AS Stake, 
					z.STATUS, 
					b.livehomescore, 
					b.liveawayscore, 
					b.bettype, 
					b.liveindicator, 
					b.betteam, 
					b.OddsType, 
					b.CurrencyName, 
					b.betfrom,
					m.HomeId, 
					m.AwayId,
					m.LeagueId,
					m.SportType
			FROM zzzbettrans z WITH (NOLOCK) 
			INNER JOIN bettrans b WITH (NOLOCK) 
					ON b.CustId = z.CustId AND b.matchid = z.matchid and b.transid = z.transid
			INNER JOIN Match m WITH (NOLOCK) 
					ON m.MatchId = b.matchId
			WHERE z.transid = @transid AND b.matchid>0
			ORDER BY z.transid
	END 

	SELECT * FROM @Data
END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransSelRecoverSpecialBets] TO [aplWeb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Acc_BettransSelRecoverSpecialBets] TO [vnteam]
GO
