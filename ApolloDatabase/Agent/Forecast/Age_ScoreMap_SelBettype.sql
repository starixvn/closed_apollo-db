USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_ScoreMap_SelBettype]    Script Date: 4/1/2013 4:50:33 PM ******/
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
 * DB			: APL.TransDB
 * Revisions	:
 *	• 20132801@Terry.Nguyen	: Implement
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN

				SELECT 1 typeid, 1 isLive, 1 isDead, 7 [1stId]
	UNION ALL	SELECT 2 typeid, 1 isLive, 1 isDead, 12 [1stId]
	UNION ALL	SELECT 3 typeid, 1 isLive, 1 isDead, 8 [1stId]
	UNION ALL	SELECT 5 typeid, 1 isLive, 1 isDead, 15 [1stId]
	UNION ALL	SELECT 20 typeid, 1 isLive, 1 isDead, 21 [1stId]
	UNION ALL	SELECT TypeId, 1 isLive, 1 isDead, 0 AS [1stId]
				FROM BetType WITH (NOLOCK)
				WHERE TypeId IN (13, 24, 25, 27, 28, 26)
	UNION ALL	SELECT 4 typeid , 0 isLive, 1 isDead, 30 [1stId]
	UNION ALL	SELECT 6 typeid , 0 isLive, 1 isDead, 0 [1stId]
	UNION ALL	SELECT 121 typeid , 1 isLive, 1 isDead, 0 [1stId]
	UNION ALL	SELECT 122 typeid , 1 isLive, 1 isDead, 0 [1stId]
	UNION ALL	SELECT 123 typeid , 1 isLive, 1 isDead, 0 [1stId]

END
