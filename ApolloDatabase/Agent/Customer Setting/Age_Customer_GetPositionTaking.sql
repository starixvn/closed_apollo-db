USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetPositionTaking]    Script Date: 4/17/2013 3:02:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Customer_GetPositionTaking]
	@CustId		INT
AS

/**
 * Created by	: Kos
 * Date			: 20130302
 * Task			: Get customer position taking and position taking 3rd
 * DB			: APL.CustDB
 * Revisions	:
 *	•	
 * Parameters:
 *	•
 */

BEGIN
	
	SET NOCOUNT ON
	
	DECLARE @AgentId INT

	SELECT @AgentId = pli.CustId
	FROM CustInfo AS pli WITH (NOLOCK)
	WHERE pli.CustId = @CustId

	SELECT 
		AgentId,
		SportType,
		BetType,
		IsLive,
		PositionTaking
	FROM CustPositionTaking WITH (NOLOCK)
	WHERE 
		CustId = @CustId
		AND (@AgentId IS NULL OR AgentId = @AgentId)

END	