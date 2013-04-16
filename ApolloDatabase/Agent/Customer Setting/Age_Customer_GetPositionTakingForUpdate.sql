USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetPositionTakingForUpdate]    Script Date: 4/16/2013 10:15:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Customer_GetPositionTakingForUpdate]
	@CustId				INT,	
	@AgentId			INT	
AS

/**
 * Created by	: Kos
 * Date			: 20130304
 * Task			: Get customer position taking and necessary information to update
 * DB			: APL.CustDB
 * Revisions	:
 *	•	20130319@Edward.Nguyen : Implement	
 * Parameters:
 *	• @AgentId		: Parent agent ID 
 *  
 */

BEGIN
	
	SET NOCOUNT ON	
	
	DECLARE @agentLevel		INT
			,@SUPERLEVEL 	INT
			,@MAXPT			INT

	SET @SUPERLEVEL	= 0
	SET @MAXPT		= 10000

	SELECT @agentLevel = AgentLevel
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId


	IF @agentLevel <> @SUPERLEVEL
		BEGIN
		   SELECT 
				ppt.SportType,
				ppt.BetType,
				ppt.IsLive,
				ppt.PositionTaking,
				apt.MinPositionTaking AS MinPositionTaking,
				apt.MaxPositionTaking AS MaxPositionTaking
			FROM 
				CustPositionTaking AS ppt WITH (NOLOCK)
				INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK) 
					ON ppt.AgentId		= apt.AgentId 
					AND ppt.SportType	= apt.SportType
					AND ppt.BetType		= apt.BetType
					AND ppt.IsLive		= apt.IsLive
			WHERE 
				ppt.CustId = @CustId 
				AND ppt.AgentId = @AgentId
		END		
	ELSE
		BEGIN
			SELECT 
				cpt.SportType
				,cpt.BetType
				,cpt.IsLive
				,@MAXPT - SUM(cpt.PositionTaking ) AS PositionTaking
				,NULL AS MinPositionTaking
				,NULL AS MaxPositionTaking
			FROM CustPositionTaking AS cpt WITH (NOLOCK)
			WHERE 
				cpt.CustId = @CustId
			GROUP BY cpt.SportType
				,cpt.BetType
				,cpt.IsLive
		END		
END										  