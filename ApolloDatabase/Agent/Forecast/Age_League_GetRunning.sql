USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_League_GetRunning]    Script Date: 4/2/2013 8:40:25 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_League_GetRunning]
	@AgID		INT,	
	@Bettypes	VARCHAR(100) = '0'--0: all, 1:1,3,7,8; 5:5,15 
AS

/**
 * Created by	: Quinn
 * Date			: 20130301
 * Task			: SELECT running Leagues for 1,3,5,7,8,15 bet types
 * DB			: APL.DB05
 * Revisions	:
 *	•
 * Parameters:
 *	@AgID: agent ID
 *	@Bettypes: bet types
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
WHERE  
	m.EventStatus = 'running'
	AND m.MatchId IN (	SELECT DISTINCT bt.MatchId 
						FROM 
							BetTrans_Agent AS bta WITH (NOLOCK)
							INNER JOIN BetTrans AS bt WITH (NOLOCK) ON bta.TransId = bt.TransId
						WHERE 
							bt.Ruben = 0 -- Match not yet settle
							AND bta.AgentId = @AgID
							AND bt.BetType IN (SELECT val FROM dbo.strSplit_Key(@Bettypes, ',')))
GROUP BY 
	m.leagueid, 
	l.leaguename, 
	m.sporttype
ORDER BY l.leaguename

