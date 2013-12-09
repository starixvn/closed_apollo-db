USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetPositionTaking]    Script Date: 5/3/2013 4:58:47 PM ******/
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
 * Task			: Get customer position taking
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	•	
 * Parameters:
 *	•
 */

BEGIN
	
	SET NOCOUNT ON
	
	SELECT 
		AgentId,
		SportType,
		BetType,
		IsLive,
		PositionTaking
	FROM CustPositionTaking WITH (NOLOCK)
	WHERE CustId = @CustId

END	