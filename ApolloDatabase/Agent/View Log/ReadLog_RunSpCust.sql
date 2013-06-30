USE [LogDB]
GO
/****** Object:  StoredProcedure [dbo].[ReadLog_RunSpCust]    Script Date: 6/29/2013 5:46:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[ReadLog_RunSpCust]	
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

	DECLARE 
		@FirstRec INT
		,@LastRec INT

	SELECT 
		@FirstRec	= ((@PageIndex - 1) * @PageSize) + 1
		,@LastRec	= ((@PageIndex * @PageSize + 1)) - 1
	

	DECLARE 
		@agentLevel		INT,
		@agentHId		HIERARCHYID,
		@actorAgentHId	HIERARCHYID,
		@agentId		INT,
		@uGroup			VARCHAR(3),
		@isCheck		BIT				= 1

	SELECT @actorAgentHId = AgentHId
	FROM RepDB.dbo.AgentInfo WITH (NOLOCK)
	WHERE AgentId = @ActorAgentId

	SELECT 
		@agentId = AgentId,
		@uGroup	= UGroup,
		@Username = Username
	FROM RepDB.dbo.CustInfo WITH (NOLOCK) 
	WHERE Username = @Username

	SELECT 
		@agentLevel	= AgentLevel,
		@agentHId = AgentHId
	FROM RepDB.dbo.AgentInfo WITH (NOLOCK)
	WHERE AgentId = @agentId

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
			RunSpCust AS rsc WITH (NOLOCK)
			INNER JOIN RepDB.dbo.CustInfo AS ci WITH (NOLOCK) 
				ON rsc.CustId	= ci.CustId
			INNER JOIN RepDB.dbo.AgentInfo AS ui WITH (NOLOCK) 
				ON rsc.UserId	= ui.AgentId																
			INNER JOIN LogAction AS la WITH (NOLOCK) 
				ON rsc.ActionId = la.ActionId
		WHERE 
			(@ActionTypeId = 0 OR (@ActionTypeId <> 0 AND (la.ActionTypeId = @ActionTypeId)))
			AND rsc.LogDate BETWEEN @From AND @To
			AND ci.Username = @Username
			AND @isCheck = 1
			AND (ui.AgentHId.IsDescendantOf(@actorAgentHId) = 1 OR ui.AgentId = 0 )
	)

	-- temp for not paging
	SET @PageSize = @TotalRows

	-- gets data
	SELECT TOP (@PageSize) *
	FROM (
			SELECT 
				rsc.LogId,
				rsc.LogDate,
				ui.Username,							
				la.ActionTypeId,
				la.ActionName,
				rsc.OldData,					
				rsc.Data,					
				ROW_NUMBER() OVER (ORDER BY rsc.LogDate DESC) AS num
			FROM 
				RunSpCust AS rsc WITH (NOLOCK)
				INNER JOIN RepDB.dbo.CustInfo AS ci WITH (NOLOCK) 
					ON rsc.CustId	= ci.CustId
				INNER JOIN RepDB.dbo.AgentInfo AS ui WITH (NOLOCK) 
					ON rsc.UserId	= ui.AgentId																
				INNER JOIN LogAction AS la WITH (NOLOCK) 
					ON rsc.ActionId = la.ActionId
			WHERE 
				(@ActionTypeId = 0 OR (@ActionTypeId <> 0 AND (la.ActionTypeId = @ActionTypeId)))
				AND rsc.LogDate BETWEEN @From AND @To
				AND ci.Username = @Username
				AND (ui.AgentHId.IsDescendantOf(@actorAgentHId) = 1 OR ui.AgentId = 0 )
		) AS Temp
	WHERE
		Temp.num >= @FirstRec
		AND Temp.num <= @LastRec
		AND @isCheck = 1
	ORDER BY
		Temp.num
		
END