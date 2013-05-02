USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_ScoreMap_SelBettype]    Script Date: 5/2/2013 12:57:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_ScoreMap_SelBettype] 
AS

/**
 * Created by	: Terry.Nguyen
 * Date			: 20130228
 * Task			: Get Bettypes for ScoreMap
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	• 20132801@Terry.Nguyen	: Implement
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN

	SET NOCOUNT ON

				SELECT 1 AS typeid, 1 AS isLive, 1 AS isDead, 7 AS [1stId]
	UNION ALL	SELECT 2 AS typeid, 1 AS isLive, 1 AS isDead, 12 AS [1stId]
	UNION ALL	SELECT 3 AS typeid, 1 AS isLive, 1 AS isDead, 8 AS [1stId]
	UNION ALL	SELECT 5 AS typeid, 1 AS isLive, 1 AS isDead, 15 AS [1stId]
	UNION ALL	SELECT 20 AS typeid, 1 AS isLive, 1 AS isDead, 21 AS [1stId]
	UNION ALL	SELECT TypeId, 1 AS isLive, 1 AS isDead, 0 AS [1stId]
				FROM BetType WITH (NOLOCK)
				WHERE TypeId IN (13, 24, 25, 27, 28, 26)
	UNION ALL	SELECT 4 AS typeid, 0 AS isLive, 1 AS isDead, 30 AS [1stId]
	UNION ALL	SELECT 6 AS typeid, 0 AS isLive, 1 AS isDead, 0 AS [1stId]
	UNION ALL	SELECT 121 AS typeid, 1 AS isLive, 1 AS isDead, 0 AS [1stId]
	UNION ALL	SELECT 122 AS typeid, 1 AS isLive, 1 AS isDead, 0 AS [1stId]
	UNION ALL	SELECT 123 AS typeid, 1 AS isLive, 1 AS isDead, 0 AS [1stId]

END
