USE [LogDB]
GO
/****** Object:  StoredProcedure [dbo].[ReadLog_RunSpAgent]    Script Date: 5/20/2013 5:22:20 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[ReadLog_RunSpAgent]	
    @ActorAgentId		INT	
	,@Username			NVARCHAR(50)	= ''	
    ,@ActionTypeId		INT				= 0
    ,@From				DATETIME
	,@To				DATETIME
	,@PageIndex			INT
	,@PageSize			INT
	,@TotalRows			INT				= 0	OUTPUT	
AS
/*  
 * Created: 05162013@Edward
 * Task : Search execute SP log
 * DB: LogDB
 *  
 * Revisions:		
 * Param's Explanation: 
*/
BEGIN
	
	SET NOCOUNT ON

	DECLARE @FirstRec INT
			,@LastRec INT

	SELECT @FirstRec	= ((@PageIndex - 1) * @PageSize) + 1
			,@LastRec	= ((@PageIndex * @PageSize + 1)) - 1
	
	DECLARE 
		@agentLevel			SMALLINT,
		@agentHId			HIERARCHYID,
		@isCheck			BIT

	SELECT 
		@agentLevel = AgentLevel,
		@agentHId = AgentHId
	FROM RepDB.dbo.AgentInfo WITH (NOLOCK)
	WHERE Username = @Username

	SET @isCheck = 1

	IF NOT EXISTS (
		SELECT TOP(1) *
		FROM RepDB.dbo.AgentInfo WITH (NOLOCK)
		WHERE 
			@agentHId.IsDescendantOf(AgentHId) = 1
			AND AgentId	= @ActorAgentId	
	)
		BEGIN					
			SET @isCheck = 0	
		END

	-- gets total rows
	SET @TotalRows = (
		SELECT COUNT(1)
		FROM 
			RunSpAgent AS rsa WITH (NOLOCK)
			INNER JOIN RepDB.dbo.AgentInfo AS ai WITH (NOLOCK) 
				ON rsa.AgentId	= ai.AgentId	
			INNER JOIN RepDB.dbo.AgentInfo AS ui WITH (NOLOCK) 
				ON rsa.UserId	= ui.AgentId																
			INNER JOIN LogAction AS la WITH (NOLOCK) 
				ON rsa.ActionId = la.ActionId
		WHERE 
			(@ActionTypeId = 0 OR (@ActionTypeId <> 0 AND (la.ActionTypeId = @ActionTypeId)))
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
				la.ActionTypeId	,
				la.ActionName,
				rsa.OldData,					
				rsa.Data,
				ROW_NUMBER() OVER (ORDER BY rsa.LogDate DESC) AS num
			FROM 
				RunSpAgent AS rsa WITH (NOLOCK)
				INNER JOIN RepDB.dbo.AgentInfo AS ai WITH (NOLOCK) 
					ON rsa.AgentId	= ai.AgentId	
				INNER JOIN RepDB.dbo.AgentInfo AS ui WITH (NOLOCK) 
					ON rsa.UserId	= ui.AgentId																
				INNER JOIN LogAction AS la WITH (NOLOCK) 
					ON rsa.ActionId = la.ActionId
			WHERE 
				(@ActionTypeId = 0 OR (@ActionTypeId <> 0 AND (la.ActionTypeId = @ActionTypeId)))
				AND rsa.LogDate BETWEEN @From AND @To
				AND ai.Username = @Username
		) AS Temp
	WHERE
		Temp.num >= @FirstRec
		AND Temp.num <= @LastRec
		AND @isCheck = 1
	ORDER BY
		Temp.num
END