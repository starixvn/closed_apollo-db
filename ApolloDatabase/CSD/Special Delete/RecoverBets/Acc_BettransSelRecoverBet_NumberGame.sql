ALTER PROCEDURE [dbo].[Acc_BettransSelRecoverBet_NumberGame]
    @transid bigint,
    @ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(1000) = '' OUTPUT
AS
/*
	Created: Sophia
	Task: Select deleted bet need to recover (Number Game)
	DB: SVRCSD.RepDB
	Revisions: 	
	
	Param's Explanation:

*/

SET NOCOUNT ON
BEGIN
	--- Check transid
	DECLARE @bettype smallint
	SET @bettype = 0
	
	select @bettype = bettype from bettrans with (NOLOCK) where transid = @transid
	
	IF ISNULL(@bettype,0) = 0 		
	BEGIN 
		SET @ErrCode = 1
		SET @ErrMsg ='Invalid TransID.'   
		RETURN
	END
	
	IF @bettype not BETWEEN 81 AND 120
	BEGIN
		SET @ErrCode = 2  
		SET @ErrMsg ='This TransID doesn''t belong to number game.'  
		RETURN
	END	
	
	
    SELECT  DISTINCT z.transid AS refno, 
			z.transid, 
			z.matchid,
			z.custid, 
			b.username,  
			b.transdate, 
			b.hdp1, 
			b.hdp2, 
			b.odds, 
			b.actual_stake,
			b.stake, 			
			z.winlost - b.actual_stake as winlost,			
			z.STATUS, 
			b.livehomescore, 
			b.liveawayscore, 
			b.bettype, 
			b.liveindicator, 
			b.betteam, 
			b.OddsType, 
			b.currency, 
			b.betfrom			
    FROM zzzbettrans (NOLOCK) z
		INNER JOIN bettrans b (NOLOCK) ON b.custid = z.custid AND b.matchid = z.matchid and b.transid = z.transid
	WHERE z.transid = @transid AND b.matchid > 0 			
    ORDER BY z.transid
END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransSelRecoverBet_NumberGame] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Acc_BettransSelRecoverBet_NumberGame] TO [vnteam]
GO
 