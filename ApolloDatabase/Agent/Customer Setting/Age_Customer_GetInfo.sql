USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetInfo]    Script Date: 7/22/2013 12:59:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Customer_GetInfo]
	@CustId		INT
AS

/**
 * Created by	: Kos
 * Date			: 20130305
 * Task			: Get customer information
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	• @20130412	: Add statuses
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON

	SELECT 
		ci.CustId,
		ci.Username,
		ci.Currency,
		ci.Status,
		ci.BetStatus,
		ci.UplineStatus,
		ci.UplineBetStatus,
		ci.MatchLimit,
		ci.VirtualMultiplier,
		ci.Danger,
		ci.CreateDate,
		ci.Creator,
		ci.LastLogged,
		ci.IPLogin,
		ci.UGroup,
		ci.DoubleCommLosing,
		ci.AgentId,
		ci.IsUGroupChanged,
		ai.Username AS AgentUsername,
		ai.AgentLevel
	FROM 
		CustInfo AS ci WITH (NOLOCK)
		INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
	WHERE CustId = @CustId
		
END
