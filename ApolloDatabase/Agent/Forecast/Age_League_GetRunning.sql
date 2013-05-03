USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_League_GetRunning]    Script Date: 5/2/2013 12:46:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_League_GetRunning]
	@AgentID	INT,
	@Bettypes	VARCHAR(100) = '0'--0: all, 1:1,3,7,8; 5:5,15 
AS

/**
 * Created by	: Quinn
 * Date			: 20130301
 * Task			: SELECT running Leagues for 1,3,5,7,8,15 bet types
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	•
 * Parameters:
 *	@AgentID	: agent ID
 *	@Bettypes	: bet types
 *  
 */

SET NOCOUNT ON

SELECT @Bettypes = 	CASE @Bettypes 
						WHEN '0' THEN '1,3,7,8,5,15' 
						WHEN '1' THEN '1,3,7,8' 
						WHEN '5' THEN '5,15' 
						ELSE '1,3,7,8,5,15' 
					END 

SELECT 
	m.LeagueId, 
	m.SportType
FROM 
	League AS l WITH (NOLOCK) 
	INNER JOIN Match AS m WITH (NOLOCK) ON l.leagueid = m.LeagueId
	LEFT JOIN Match_remark_ex e WITH (NOLOCK) ON e.MatchId = m.MatchId
WHERE  
	e.EventStatus = 'running'
	AND m.MatchId IN (	SELECT DISTINCT bt.MatchId 
						FROM 
							BetTrans_Agent AS bta WITH (NOLOCK)
							INNER JOIN BetTrans AS bt WITH (NOLOCK) ON bta.TransId = bt.TransId
						WHERE 
							bt.Ruben = 0 -- Match not yet settle
							AND bta.AgentId = @AgentID
							AND bt.BetType IN (SELECT val FROM dbo.strSplit_Key(@Bettypes, ',')))
GROUP BY 
	m.leagueid, 
	l.leaguename, 
	m.sporttype
ORDER BY l.leaguename
