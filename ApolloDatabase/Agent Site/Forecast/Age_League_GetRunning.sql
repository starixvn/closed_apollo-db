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
FROM Match AS m WITH (NOLOCK) 
WHERE  
	m.EventStatus = 'running'
	AND m.MatchId IN (	SELECT DISTINCT MatchId 
						FROM BetTrans_Agent WITH (NOLOCK)							
						WHERE 	StatusID IN (0,1)
							AND AgentId = @AgentID
							AND BetType IN (SELECT val FROM dbo.strSplit_Key(@Bettypes, ',')))
GROUP BY 
	m.leagueid, 
	m.sporttype
ORDER BY m.leagueid
