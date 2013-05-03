USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetPositionTakingForUpdate]    Script Date: 5/3/2013 4:49:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_GetPositionTakingForUpdate]
	@CustId		INT,
	@AgentId	INT
AS

/**
 * Created by	: Kos
 * Date			: 20130304
 * Task			: Get customer position taking and necessary information to update
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	•	20130319@Edward.Nguyen : Implement	
 * Parameters:
 *	• @AgentId	: Parent agent ID 
 *  
 */

BEGIN
	
	SET NOCOUNT ON	
	
	DECLARE 
		@agentLevel		SMALLINT,
		@SUPERLEVEL 	INT,
		@MAXPT			INT,
		@isDirect		BIT

	SET @SUPERLEVEL	= 0
	SET @MAXPT		= 10000

	SELECT @agentLevel = AgentLevel
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId
	
	-- Check for is direct member
	SET @isDirect = 0

	IF EXISTS (	SELECT 1 FROM CustInfo WHERE AgentId = @AgentId AND CustId = @CustId )
		SET @isDirect = 1
	-- End check for is direct member

	IF @agentLevel <> @SUPERLEVEL
		BEGIN		
			
			IF @isDirect = 1
				BEGIN
					SELECT 
						ppt.SportType,
						ppt.BetType,
						ppt.IsLive,
						ppt.PositionTaking,
						apt.MinGivenPositionTaking AS MinGivenPositionTaking,
						apt.MaxGivenPositionTaking AS MaxGivenPositionTaking
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
					
					DECLARE @childAgentId INT

					SELECT DISTINCT @childAgentId = ai.AgentId
					FROM 
						CustPositionTaking AS cpt WITH (NOLOCK)	
						INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON cpt.AgentId = ai.AgentId
					WHERE 
						cpt.CustId = @CustId	
						AND cpt.AgentId IN (	SELECT AgentId 
												FROM AgentInfo WITH (NOLOCK)
												WHERE ParentId = @AgentId )

					SELECT 
						cpt.SportType,
						cpt.BetType,
						cpt.IsLive,
						cpt.PositionTaking,
						CASE 
							WHEN temp.MinOfPositionTaking > 0 THEN temp.MinOfPositionTaking
							ELSE 0
						END AS MinGivenPositionTaking,
						temp.MaxOfPositionTaking AS MaxGivenPositionTaking
					FROM 
						CustPositionTaking AS cpt WITH (NOLOCK)
						INNER JOIN (
							SELECT 
								downCust.CustId,
								downCust.SportType,
								downCust.BetType,
								downCust.IsLive,
								apt.MinGivenPositionTaking - downCust.SumOfDownlinePT AS MinOfPositionTaking,
								CASE 
									WHEN capt.MaxUpperPositionTaking > apt.MinGivenPositionTaking - downCust.SumOfDownlinePT
										THEN capt.MaxUpperPositionTaking
									ELSE apt.MinGivenPositionTaking - downCust.SumOfDownlinePT
								END AS MaxOfPositionTaking
							FROM 
								AgentPositionTaking AS apt WITH (NOLOCK)
								INNER JOIN (
									SELECT 
										cpt.CustId,
										cpt.SportType,
										cpt.BetType,
										cpt.IsLive,
										SUM(cpt.PositionTaking) AS SumOfDownlinePT
									FROM 
										CustPositionTaking AS cpt WITH (NOLOCK)
										INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON cpt.AgentId = ai.AgentId	
									WHERE 
										cpt.CustId = @custId
										AND ai.AgentLevel > @agentLevel 
									GROUP BY  
										cpt.CustId,
										cpt.SportType,
										cpt.BetType,
										cpt.IsLive
								) AS downCust 
									ON 	apt.SportType	= downCust.SportType
										AND apt.BetType	= downCust.BetType
										AND apt.IsLive	= downCust.IsLive
								INNER JOIN AgentPositionTaking AS capt WITH (NOLOCK)
									ON 	apt.SportType	= capt.SportType
										AND apt.BetType = capt.BetType
										AND apt.IsLive	= capt.IsLive
							WHERE 
								apt.AgentId = @AgentId
								AND capt.AgentId = @childAgentId
						) AS temp
							ON 	cpt.SportType = temp.SportType
								AND cpt.BetType = temp.BetType
								AND cpt.IsLive = temp.IsLive
					WHERE 
						cpt.CustId = @CustId
						AND cpt.AgentId = @AgentId
				END			

		END		
	-- Get PT for super
	--ELSE
	--	BEGIN
	--		SELECT 
	--			cpt.SportType
	--			,cpt.BetType
	--			,cpt.IsLive
	--			,@MAXPT - SUM(cpt.PositionTaking ) AS PositionTaking
	--			,NULL AS MinGivenPositionTaking
	--			,NULL AS MaxGivenPositionTaking
	--		FROM CustPositionTaking AS cpt WITH (NOLOCK)
	--		WHERE 
	--			cpt.CustId = @CustId
	--		GROUP BY cpt.SportType
	--			,cpt.BetType
	--			,cpt.IsLive
	--	END		
END