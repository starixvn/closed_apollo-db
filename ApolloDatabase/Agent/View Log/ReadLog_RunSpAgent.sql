USE [LogDB]
GO
/****** Object:  StoredProcedure [dbo].[ReadLog_RunSpAgent]    Script Date: 7/17/2013 4:24:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[ReadLog_RunSpAgent]	
	@ActorAgentId	INT	
	,@Username		NVARCHAR(50)	= ''	
	,@ActionTypeId	INT				= 0
	,@From			DATETIME
	,@To			DATETIME
	,@PageIndex		INT
	,@PageSize		INT
	,@TotalRows		INT				= 0		OUTPUT	
AS

/*  
 * Created: 05162013@Edward
 * Task : Search execute SP log
 * DB: SVRLOG.LogDB
 *  
 * Revisions:		
 * Param's Explanation: 
*/

BEGIN
	
	SET NOCOUNT ON

	DECLARE 
		@FirstRec INT
		,@LastRec INT

	SELECT 
		@FirstRec	= ((@PageIndex - 1) * @PageSize) + 1
		,@LastRec	= ((@PageIndex * @PageSize + 1)) - 1

	DECLARE @Temp TABLE (
		AgentId		INT,
		AgentHId	HIERARCHYID,
		Username	NVARCHAR(50) )
	
	DECLARE 
		@agentId		INT,
		@agentHId		HIERARCHYID,
		@actorAgentHId	HIERARCHYID,
		@isCheck		BIT				= 1

	INSERT INTO @Temp
	SELECT * FROM OPENQUERY(SVRAGE, 'SELECT AgentId, AgentHId, Username FROM [RepDB].[dbo].[AgentInfo] WITH (NOLOCK)')

	SELECT @actorAgentHId = AgentHId
	FROM @Temp
	WHERE AgentId = @ActorAgentId

	SELECT 
		@agentId = AgentId,
		@agentHId = AgentHId
	FROM @Temp
	WHERE Username = @Username

	IF @agentHId.IsDescendantOf(@actorAgentHId) <> 1
		BEGIN
			SET @isCheck = 0	
		END

	-- gets total rows
	SET @TotalRows = (
		SELECT COUNT(1)
		FROM 
			dbo.RunSpAgent AS rsa WITH (NOLOCK)
			INNER JOIN @Temp AS ai ON rsa.AgentId = ai.AgentId
			INNER JOIN @Temp AS ui ON rsa.UserId = ui.AgentId
			INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON rsa.ActionId = la.ActionId
		WHERE 
			(@ActionTypeId = 0 OR la.ActionTypeId = @ActionTypeId)
			AND rsa.LogDate BETWEEN @From AND @To
			AND ai.Username = @Username
			AND @isCheck = 1
	)

	-- gets data
	SELECT TOP (@PageSize) *
	FROM (
			SELECT 
				rsa.LogId,
				rsa.LogDate,
				ui.Username,
				adi.Username AS AdminUsername,
				la.ActionTypeId	,
				la.ActionName,
				rsa.OldData,
				rsa.Data,
				ROW_NUMBER() OVER (ORDER BY rsa.LogDate DESC) AS num
			FROM 
				dbo.RunSpAgent AS rsa WITH (NOLOCK)
				INNER JOIN @Temp AS ai ON rsa.AgentId = ai.AgentId	
				INNER JOIN @Temp AS ui ON rsa.UserId	= ui.AgentId
				INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON rsa.ActionId = la.ActionId
				LEFT JOIN SVRAGE.RepDB.dbo.AdminInfo AS adi WITH (NOLOCK) ON rsa.AdminId = adi.AdminId
			WHERE 
				(@ActionTypeId = 0 OR la.ActionTypeId = @ActionTypeId)
				AND rsa.LogDate BETWEEN @From AND @To
				AND ai.Username = @Username
		) AS Temp
	WHERE 
		@isCheck = 1 
		AND Temp.num BETWEEN @FirstRec AND @LastRec
	ORDER BY Temp.num

	DELETE @Temp
END