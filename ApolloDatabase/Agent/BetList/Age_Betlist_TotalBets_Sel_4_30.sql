USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Betlist_TotalBets_Sel_4_30]    Script Date: 3/25/2013 4:21:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Age_Betlist_TotalBets_Sel_4_30]
	@AgentId INT,
	@Language VARCHAR(2) = 'E'
 AS
/**
 * Created by	: Kaden
 * Date			: 20130301
 * Task			: Retrieve total bet of 1St Correct Score/Correct Score. (BetType: 4,30)
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	•
 * Parameters:
 *	@AgentId: agent ID
 *	@Language: default English
 *  
 */
 
SET NOCOUNT ON
	SELECT 
		m.sporttype,
		m.leagueID, 
		m.matchid,
		m.matchcode,
		m.homeID,
		m.awayID,
		bt.Username,
		bt.BetType,		
		bt.TransId,
		bt.RefNo,
		CONVERT(FLOAT, bt.Hdp1) AS Hdp1, 
		CONVERT(FLOAT, bt.Hdp2) AS Hdp2, 
		bt.Odds,
		bt.MOdds,
		CASE WHEN bt.Status = 'running' AND IsNull(bt.SecAcceptFlag, 0) = 1 and IsNull(bt.CheckTime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
				 ELSE bt.Status 
				 END AS Status,
		bt.DoubleCommLosing,
		bt.Stake,
		bt.Actual_Stake,
		bt.TransDate,		
		bt.BetTeam,
		bt.BetId,
		bta.APositionTaking,
		bta.ADiscount,
		bt.LiveHomeScore,
		bt.LiveAwayScore,
		bt.LiveIndicator, 
		bt.IP,
		ISNULL(m.IsNeutral, CONVERT(BIT,0)) AS IsNeutral,
		bt.OddStype
 	FROM 
		Match m WITH (NOLOCK)
		INNER JOIN BetTrans AS bt  WITH (NOLOCK) ON m.MatchId = bt.MatchId
		INNER JOIN BetTrans_Agent AS bta WITH (NOLOCK) ON bta.TransId = bt.TransId
	WHERE 
		bta.AgentId = @AgentId
		AND bt.BetType IN (4,30)
		AND bt.StatusId IN (0,1)
	ORDER BY bt.Status, bt.TransId

GO
GRANT VIEW DEFINITION ON [dbo].[Age_Betlist_TotalBets_Sel_4_30] TO [aplweb]


