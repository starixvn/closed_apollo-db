USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[DBA_Customer_GetPT]    Script Date: 4/23/2013 1:08:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[DBA_Customer_GetPT]
	@InputCust	VARCHAR(30),
	@SportType	SMALLINT	= 1,
	@BetType	SMALLINT	= 1,
	@IsLive		BIT			= 0
AS

/**
 * Created by	: Kos
 * Date			: 20130305
 * Task			: Get customer position taking and upline position taking
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

	DECLARE @CustId					INT
	DECLARE @CustUsername			VARCHAR(50)
	DECLARE @AgentId				INT
	DECLARE @AgentHId				HIERARCHYID
	DECLARE @AgentUsername			VARCHAR(50)
	DECLARE @MaxUpperPositionTaking	SMALLINT
	DECLARE @MaxGivenPositionTaking		SMALLINT
	DECLARE @MinGivenPositionTaking		SMALLINT
	DECLARE @PositionTaking			SMALLINT

	SELECT @InputCust = LTRIM(RTRIM(@InputCust))

	IF ISNUMERIC(@InputCust) = 0
		BEGIN
			SELECT 
				@CustId = ci.CustId,
				@CustUsername = ci.Username,
				@AgentId = ci.AgentId,
				@AgentHId = ai.AgentHId,
				@AgentUsername = ai.Username
			FROM 
				CustInfo AS ci WITH (NOLOCK)
				INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
			WHERE ci.Username = @InputCust
		END
	ELSE
		BEGIN
			SELECT 
				@CustId = ci.CustId,
				@CustUsername = ci.Username,
				@AgentId = ci.AgentId,
				@AgentHId = ai.AgentHId,
				@AgentUsername = ai.Username
			FROM 
				CustInfo AS ci WITH (NOLOCK)
				INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
			WHERE ci.CustId = @InputCust
		END

	PRINT 'Username: ' + ISNULL(@CustUsername, '')
	PRINT 'Customer ID: ' + CAST(@CustId AS VARCHAR(10))
	PRINT 'Agent: ' + ISNULL(@AgentUsername, '')
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
		apt.MinGivenPositionTaking,
		cpt.PositionTaking
	FROM 
		AgentPositionTaking AS apt WITH (NOLOCK)
		INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON apt.AgentId = ai.AgentId
		INNER JOIN CustPositionTaking AS cpt WITH (NOLOCK) ON apt.AgentId = cpt.AgentId
	WHERE
		@AgentHId.IsDescendantOf(ai.AgentHId) = 1
		AND apt.SportType = @SportType
		AND apt.BetType = @BetType
		AND apt.IsLive = @IsLive
		AND cpt.CustId = @CustId
		AND cpt.SportType = @SportType
		AND cpt.BetType = @BetType
		AND cpt.IsLive = @IsLive
	ORDER BY ai.AgentLevel ASC
	
	PRINT @strLine

	PRINT 
		'| ' + CAST('Agent ID' AS CHAR(10)) 
		+ '| ' + CAST('Username' AS CHAR(30))
		+ '| ' + CAST('Preset' AS CHAR(10)) 
		+ '| ' + CAST('Max' AS CHAR(10)) 
		+ '| ' + CAST('Min' AS CHAR(10)) 
		+ '| ' + CAST('Mem' AS CHAR(10)) 

	PRINT @strLine

	OPEN AgentCursor

	FETCH NEXT FROM AgentCursor
	INTO 
		@AgentId, 
		@AgentUsername,
		@MaxUpperPositionTaking,
		@MaxGivenPositionTaking,
		@MinGivenPositionTaking,
		@PositionTaking

	WHILE @@FETCH_STATUS = 0
		BEGIN
			PRINT 
				'| ' + CAST(@AgentId AS CHAR(10)) 
				+ '| ' + CAST(@AgentUsername AS CHAR(30))
				+ '| ' + CAST(CAST(@MaxUpperPositionTaking AS FLOAT) / CAST(10000 AS FLOAT) AS CHAR(10)) 
				+ '| ' + CAST(CAST(@MaxGivenPositionTaking AS FLOAT) / CAST(10000 AS FLOAT) AS CHAR(10)) 
				+ '| ' + CAST(CAST(@MinGivenPositionTaking AS FLOAT) / CAST(10000 AS FLOAT) AS CHAR(10)) 
				+ '| ' + CAST(CAST(@PositionTaking AS FLOAT) / CAST(10000 AS FLOAT) AS CHAR(10)) 

			PRINT @strLine

			FETCH NEXT FROM AgentCursor
			INTO 
				@AgentId, 
				@AgentUsername,
				@MaxUpperPositionTaking,
				@MaxGivenPositionTaking,
				@MinGivenPositionTaking,
				@PositionTaking
		END

	CLOSE AgentCursor

	DEALLOCATE AgentCursor
		
END	




