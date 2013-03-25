CREATE  PROCEDURE [dbo].[Acc_BettransSelRecoverSpecialBets]
    @transid bigint,
    @Type SMALLINT = 0,
    @ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(1000) = '' OUTPUT
AS
/*
Created: Sophia
Date:  20130307
Task: get data to recover bet
DB: SVRCSD.repDB
Revisions: 

	
Param's Explanation:
	- @Type: sports type
		0: Sportsbook
		1: Virtual sports
*/

SET NOCOUNT ON
BEGIN
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
		RETURN
	END
	
	IF NOT (@bettype < 31  or @bettype between 121 AND 999) AND @Type = 0  
	BEGIN
		SET @ErrCode = 2  
		SET @ErrMsg ='This TransID doesn''t belong to sportsbook.'  
		RETURN
	END	
	
	
    SELECT  DISTINCT z.transid AS refno, 
			z.transid, 
			z.CustId, 
			b.username, 
			b.transdate, 
			b.hdp1, 
			b.hdp2, 
			b.odds, 
			b.stake AS StakePositiontaking, 
			z.STATUS, 
			b.livehomescore, 
			b.liveawayscore, 
			b.bettype, 
			b.liveindicator, 
			b.betteam, 
			b.OddsType, 
			b.currency, 
			b.betfrom
    FROM zzzbettrans (nolock) z
		INNER JOIN bettrans b (nolock)ON b.CustId = z.CustId AND b.matchid = z.matchid and b.transid = z.transid
    WHERE z.transid = @transid AND b.matchid>0
    ORDER BY z.transid
END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransSelRecoverSpecialBets] TO [aplWeb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Acc_BettransSelRecoverSpecialBets] TO [vnteam]
GO
