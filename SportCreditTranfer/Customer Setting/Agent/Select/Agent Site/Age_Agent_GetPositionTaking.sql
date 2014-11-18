USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetPositionTaking]    Script Date: 5/3/2013 5:04:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_GetPositionTaking]
	@AgentId	INT
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
	
	SELECT 
		SportType,
		BetType,
		IsLive,
		MaxUpperPositionTaking,
		MaxGivenPositionTaking,
		MinGivenPositionTaking
	FROM AgentPositionTaking WITH (NOLOCK)
	WHERE AgentId = @AgentId
	
END

GRANT EXECUTE ON [dbo].[Age_Agent_GetPositionTaking] TO [aplweb] AS [dbo]

