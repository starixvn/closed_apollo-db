ALTER PROCEDURE [dbo].[Acc_BettransSelSpecialDel_MixParlay]	 
	@Refno bigint,	
	@Transid bigint,
	@CurrencyID tinyint
AS  
/*  
 Created by: Sophia
 Date: 20130307
 Original:
 Task: get tickets of mix parlay by Refno
 DB: SVRCSD.RepDB
  
 Revisions:  
	 
 Explanation's Param:  
	
  
*/
BEGIN
	SET NOCOUNT ON 
	DECLARE @CurrencyName nvarchar(50)
	
	SELECT @CurrencyName=currency 
	FROM dbo.exchange WITH(NOLOCK) 
	WHERE exchangeid=@CurrencyID
			
	SELECT
		b.transid,		
		b.bettype,
		m.homeid,
		m.awayid,
		b.hdp1, 
		b.hdp2, 
		b.odds,
		b.betteam,
		b.livehomescore, 
		b.liveawayscore, 
		b.liveindicator, 
		m.leagueid,
		m.sporttype,
		m.isNeutral as IsNeutral,
		m.matchid,
		m.matchcode
		,b.stake AS StakePositionTaking
		,@CurrencyName AS currency
		,CASE WHEN transid=@Transid THEN 1 ELSE 0 END AS IsDeleted
		,b.statusid
	FROM dbo.BettransM AS b with (nolock)		
		INNER JOIN match AS m with (nolock) ON b.matchid=m.matchid
			AND refno=@refno
	ORDER BY b.transid
	
	SET NOCOUNT OFF
END
 
GO
GRANT EXECUTE ON [dbo].[Acc_BettransSelSpecialDel_MixParlay] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Acc_BettransSelSpecialDel_MixParlay] TO [vnteam]
GO 