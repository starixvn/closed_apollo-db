USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetPositionTaking]    Script Date: 3/29/2013 9:58:25 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER PROCEDURE [dbo].[Age_Agent_GetPositionTaking]
	@AgentId		INT	
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Get agent position taking and position taking 3rd
 * DB			: APL.CustDB
 * Revisions	:
 *	•	20132802@Edward : Implement
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	SELECT apt.SportType,
			apt.BetType,
			apt.IsLive,
			apt.PresetPositionTaking,
			apt.MaxPositionTaking			
	FROM AgentPositionTaking AS apt WITH (NOLOCK)
	WHERE apt.AgentId = @AgentId
	UNION
	SELECT apt.SportType,
			apt.BetType,
			apt.IsLive,
			apt.PresetPositionTaking,
			apt.MaxPositionTaking			
	FROM AgentPositionTaking3rd AS apt WITH (NOLOCK)
	WHERE apt.AgentId = @AgentId

END

GRANT EXECUTE ON [dbo].[Age_Agent_GetPositionTaking] TO [aplweb] AS [dbo]

