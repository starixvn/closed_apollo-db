USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Forecast_OddsGetTopByMatch]    Script Date: 4/1/2013 3:31:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Forecast_OddsGetTopByMatch]
	@matchid INT,
	@bettype INT = 1
AS

/**
 * Created by	: Quinn
 * Date			: 20130304
 * Task			: Forecast at Agent Site 
 * DB			: APL.REPDB
 * Revisions	:
 *	•
 * Parameters:
 *	@matchid: match ID
 *  @bettype: bet type
 */

SET NOCOUNT ON

SELECT TOP 1
	hdp1,
	hdp2,
	odds1a,
	odds2a,
	o.livehomescore, 
	o.liveawayscore, 
	switch, 
	oddsstatus,
	m.homeid,
	m.awayid,
	ISNULL(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
FROM 
	odds AS o WITH (NOLOCK)
	LEFT JOIN match AS M WITH (NOLOCK) ON o.matchid = M.matchid
WHERE 
	bettype = @bettype 
	AND o.matchid = @matchid
ORDER BY oddsid DESC
