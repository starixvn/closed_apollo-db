USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[DBA_Agent_GetPT]    Script Date: 4/23/2013 1:07:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[DBA_Agent_GetPT]
	@InputAgent	VARCHAR(30),
	@SportType	SMALLINT	= 1,
	@BetType	SMALLINT	= 1,
	@IsLive		BIT			= 0
AS

/**
 * Created by	: Kos
 * Date			: 20130305
 * Task			: Get agent position taking and upline position taking
 * DB			: APL.CustDB
 * Revisions	:
 *	• 
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON	

	DECLARE @AgentId				INT
	DECLARE @AgentHId				HIERARCHYID
	DECLARE @Username				VARCHAR(50)
	DECLARE @MaxUpperPositionTaking	SMALLINT
	DECLARE @MaxGivenPositionTaking		SMALLINT
	DECLARE @MinGivenPositionTaking		SMALLINT

	SELECT @InputAgent = LTRIM(RTRIM(@InputAgent))

	IF ISNUMERIC(@InputAgent) = 0
		BEGIN
			SELECT 
				@AgentId = AgentId,
				@AgentHId = AgentHId,
				@Username = Username
			FROM AgentInfo WITH (NOLOCK)
			WHERE Username = @InputAgent
		END
	ELSE
		BEGIN
			SELECT 
				@AgentId = AgentId,
				@AgentHId = AgentHId,
				@Username = Username
			FROM AgentInfo WITH (NOLOCK)
			WHERE AgentId = @InputAgent
		END

	PRINT 'Username: ' + ISNULL(@Username, '')
	PRINT 'Agent ID: ' + CAST(@AgentId AS VARCHAR(10))
	PRINT 'Sport type: ' + CAST(@SportType AS VARCHAR(10))
	PRINT 'Bet type: ' + CAST(@BetType AS VARCHAR(10))
	PRINT 'Live indicator: ' + CAST(@IsLive AS VARCHAR(10))

	DECLARE @strBlank CHAR(10)
	DECLARE @strLine VARCHAR(100)

	SET @strBlank = ' | '
	SET @strLine = ' -------------------------------------------------------------------------------------------'

	DECLARE AgentCursor CURSOR FOR
	SELECT 
		ai.AgentId,
		ai.Username,
		apt.MaxUpperPositionTaking,
		apt.MaxGivenPositionTaking,
		apt.MinGivenPositionTaking
	FROM 
		AgentPositionTaking AS apt WITH (NOLOCK)
		INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON apt.AgentId = ai.AgentId
	WHERE
		@AgentHId.IsDescendantOf(ai.AgentHId) = 1
		AND apt.SportType = @SportType
		AND apt.BetType = @BetType
		AND apt.IsLive = @IsLive
	ORDER BY ai.AgentLevel ASC
	
	PRINT @strLine

	PRINT 
		'| ' + CAST('Agent ID' AS CHAR(10)) 
		+ '| ' + CAST('Username' AS CHAR(30))
		+ '| ' + CAST('Preset' AS CHAR(10)) 
		+ '| ' + CAST('Max' AS CHAR(10)) 
		+ '| ' + CAST('Min' AS CHAR(10)) 

	PRINT @strLine

	OPEN AgentCursor

	FETCH NEXT FROM AgentCursor
	INTO 
		@AgentId, 
		@Username,
		@MaxUpperPositionTaking,
		@MaxGivenPositionTaking,
		@MinGivenPositionTaking

	WHILE @@FETCH_STATUS = 0
		BEGIN
			PRINT 
				'| ' + CAST(@AgentId AS CHAR(10)) 
				+ '| ' + CAST(@Username AS CHAR(30))
				+ '| ' + CAST(CAST(@MaxUpperPositionTaking AS FLOAT) / CAST(10000 AS FLOAT) AS CHAR(10)) 
				+ '| ' + CAST(CAST(@MaxGivenPositionTaking AS FLOAT) / CAST(10000 AS FLOAT) AS CHAR(10)) 
				+ '| ' + CAST(CAST(@MinGivenPositionTaking AS FLOAT) / CAST(10000 AS FLOAT) AS CHAR(10)) 

			PRINT @strLine

			FETCH NEXT FROM AgentCursor
			INTO 
				@AgentId, 
				@Username,
				@MaxUpperPositionTaking,
				@MaxGivenPositionTaking,
				@MinGivenPositionTaking
		END

	CLOSE AgentCursor

	DEALLOCATE AgentCursor
		
END




