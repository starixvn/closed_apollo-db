USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetPositionTakingForUpdate]    Script Date: 3/29/2013 9:58:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER PROCEDURE [dbo].[Age_Agent_GetPositionTakingForUpdate]
	@AgentId		INT		
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Get agent and its parent position taking and position taking 3rd
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
	DECLARE @parentId		INT
			,@agentLevel	INT
			,@maxPT			INT

	SET @maxPT = 9000

	---- Select parent og agent
	SELECT @parentId		= ai.ParentId
			,@agentLevel	= ai.AgentLevel
	FROM 
		AgentInfo AS ai WITH (NOLOCK)
	WHERE ai.AgentId = @AgentId

	SELECT apt.SportType,
			apt.BetType,
			apt.IsLive,
			apt.PresetPositionTaking,
			CASE WHEN @agentLevel = 1
				THEN @maxPT
				ELSE aptp.MaxPositionTaking
			END	AS ParentMaxPositionTaking,			
			apt.MaxPositionTaking
	FROM AgentPositionTaking AS apt WITH (NOLOCK)
		LEFT JOIN (
			SELECT apt.SportType,
				apt.BetType,
				apt.IsLive,
				apt.PresetPositionTaking,			
				apt.MaxPositionTaking
			FROM AgentPositionTaking AS apt WITH (NOLOCK)	
			WHERE apt.AgentId = @parentId
		) AS aptp
			ON apt.SportType = aptp.SportType
			AND apt.BetType = aptp.BetType
			AND apt.IsLive = aptp.IsLive
	WHERE apt.AgentId = @AgentId

	UNION

	SELECT apt.SportType,
			apt.BetType,
			apt.IsLive,
			apt.PresetPositionTaking,
			CASE WHEN @agentLevel = 1
				THEN @maxPT
				ELSE aptp.MaxPositionTaking
			END	AS ParentMaxPositionTaking,				
			apt.MaxPositionTaking
	FROM AgentPositionTaking3rd AS apt WITH (NOLOCK)
		LEFT JOIN (
			SELECT apt.SportType,
				apt.BetType,
				apt.IsLive,
				apt.PresetPositionTaking,			
				apt.MaxPositionTaking
			FROM AgentPositionTaking3rd AS apt WITH (NOLOCK)	
			WHERE apt.AgentId = @parentId
		) AS aptp
			ON apt.SportType = aptp.SportType
			AND apt.BetType = aptp.BetType
			AND apt.IsLive = aptp.IsLive
	WHERE apt.AgentId = @AgentId
END



