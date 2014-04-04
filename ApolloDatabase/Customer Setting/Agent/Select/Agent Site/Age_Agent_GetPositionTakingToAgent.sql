ALTER PROCEDURE [dbo].[Age_Agent_GetPositionTakingToAgent]
	@ActorAgentId	INT,
	@AgentId		INT				= -1,
	@Username		NVARCHAR(50)	= '',
	@SportType		SMALLINT,
	@BetType		SMALLINT,
	@IsLive			BIT	
AS

/**
 * Created by	: Edward
 * Date			: 20130417
 * Task			: Get agent position taking from current login agent to agent
 * DB			: SVRCUST.CustDB
 * Revisions	:
 	•	20130712@Edward : Get the same structure in DB	
	•	20131119@Dan : optimize performance 
	•	20140404@Sophia: Get AgentId by username

 * Parameters:
 	@ActorAgentId: parent agent, the agent is currently login
 	@AgentId: child agent which parent is viewing
	@Username: : username of child agent that parent agent is viewing 
	@SportType: sporttype		
	@BetType: bettype		
	@IsLive:is live or nonlive		
 */

BEGIN
	
	SET NOCOUNT ON
	
	DECLARE 
		@agentHId			HIERARCHYID,
		@isCheck			BIT,
		@actorAgentLevel	SMALLINT,
		@actorAgentHId		HIERARCHYID	
		
	--search by username
	IF ISNULL(@Username,'') <> ''
		SELECT @agentHId = AgentHId, @AgentId = AgentId
		FROM AgentInfo WITH (NOLOCK)
		WHERE Username = @Username	
	ELSE
		--search by agentid
		SELECT @agentHId = AgentHId
		FROM AgentInfo WITH (NOLOCK)
		WHERE AgentId = @AgentId 
		
	SELECT @actorAgentLevel = AgentLevel, @actorAgentHId=AgentHId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @ActorAgentId
	
	IF NOT(@agentHId.IsDescendantOf(@actorAgentHId) = 1)
		BEGIN		
			--no data
			SELECT NULL AS AgentId,
				NULL AS AgentLevel,
				NULL AS Username,
				NULL AS MaxUpperPositionTaking,
				NULL AS MaxGivenPositionTaking,
				NULL AS MinGivenPositionTaking
			WHERE 0=1
			RETURN;			
		END

	;WITH Agent_CTE(agentid, Parentid, AgentLevel, username) as 
	(
		SELECT ai.AgentId as agentid, 
				Parentid, 
				AgentLevel,
				username
		FROM AgentInfo ai  WITH (NOLOCK)
		WHERE AgentID = @AgentId
		UNION ALL
		SELECT ai.AgentId as agentid,
			   ai.Parentid as Parentid,
			   ai.AgentLevel,
				ai.username
		FROM AgentInfo ai  WITH (NOLOCK) 
			INNER JOIN Agent_CTE ac ON ac.Parentid = ai.AgentId
		WHERE ai.AgentLevel >= @actorAgentLevel
	)

	SELECT 
		apt.AgentId,
		AgentLevel,
		Username,
		apt.MaxUpperPositionTaking,
		apt.MaxGivenPositionTaking,
		apt.MinGivenPositionTaking
	FROM 
		AgentPositionTaking AS apt WITH (NOLOCK)
		JOIN Agent_CTE ap on ap.agentid=apt.AgentId		
	WHERE 
		apt.SportType	= @SportType
		AND apt.BetType	= @BetType
		AND apt.IsLive	= @IsLive				
	ORDER BY AgentLevel
	
	
	
END


