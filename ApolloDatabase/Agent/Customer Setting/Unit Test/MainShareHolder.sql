USE [CustDB]
GO

DECLARE	@custId INT,
		@SportType			SMALLINT,
		@BetType			SMALLINT,
		@IsLive				BIT	

DECLARE	@TableTempCompare TABLE(
			AgentId					INT
			,AgentLevel				SMALLINT
			,Username				NVARCHAR(50)
			,MaxUpperPositionTaking	SMALLINT
			,MaxGivenPositionTaking	SMALLINT
			,MinGivenPositionTaking	SMALLINT
			,PositionTaking			SMALLINT)

INSERT INTO @TableTempCompare VALUES (206,1,'age-ed--0-206',1500,8500,1500,1500)
INSERT INTO @TableTempCompare VALUES (210,2,'age-ed--206-210',1500,7000,0,1000)
INSERT INTO @TableTempCompare VALUES (214,3,'age-ed--210-214',1000,5000,4000,2000)
INSERT INTO @TableTempCompare VALUES (218,4,'age-ed--214-218',1000,3000,1000,1500)
INSERT INTO @TableTempCompare VALUES (222,5,'age-ed--218-222',1500,1500,0,500)

SELECT 
		@custId			= 128453
		,@SportType		= 1
		,@BetType		= 1
		,@IsLive		= 1

/*----- Reset Data-----*/
UPDATE AgentPositionTaking WITH (ROWLOCK,UPDLOCK)
SET MaxUpperPositionTaking	= 1000
	,MaxGivenPositionTaking	= 9000
	,MinGivenPositionTaking	= 1500
WHERE AgentId = 206

UPDATE AgentPositionTaking WITH (ROWLOCK,UPDLOCK)
SET MaxUpperPositionTaking	= 1500
	,MaxGivenPositionTaking	= 7000
	,MinGivenPositionTaking	= 0
WHERE AgentId = 210

UPDATE AgentPositionTaking WITH (ROWLOCK,UPDLOCK)
SET MaxUpperPositionTaking	= 1500
	,MaxGivenPositionTaking	= 7000
	,MinGivenPositionTaking	= 0
WHERE AgentId = 207

UPDATE AgentPositionTaking WITH (ROWLOCK,UPDLOCK)
SET MaxUpperPositionTaking	= 1500
	,MaxGivenPositionTaking	= 7000
	,MinGivenPositionTaking	= 0
WHERE AgentId = 208

UPDATE AgentPositionTaking WITH (ROWLOCK,UPDLOCK)
SET MaxUpperPositionTaking	= 1500
	,MaxGivenPositionTaking	= 7000
	,MinGivenPositionTaking	= 0
WHERE AgentId = 209

UPDATE AgentPositionTaking WITH (ROWLOCK,UPDLOCK)
SET MaxUpperPositionTaking	= 1000
	,MaxGivenPositionTaking	= 5000
	,MinGivenPositionTaking	= 4000
WHERE AgentId = 214

UPDATE AgentPositionTaking WITH (ROWLOCK,UPDLOCK)
SET MaxUpperPositionTaking	= 1000
	,MaxGivenPositionTaking	= 3000
	,MinGivenPositionTaking	= 1000
WHERE AgentId = 218

UPDATE AgentPositionTaking WITH (ROWLOCK,UPDLOCK)
SET MaxUpperPositionTaking	= 1500
	,MaxGivenPositionTaking	= 1500
	,MinGivenPositionTaking	= 0
WHERE AgentId = 222

UPDATE CustPositionTaking WITH (ROWLOCK,UPDLOCK)
SET PositionTaking = 1500
WHERE AgentId = 206 AND CustId = @custId

UPDATE CustPositionTaking WITH (ROWLOCK,UPDLOCK)
SET PositionTaking = 1000
WHERE AgentId = 210 AND CustId = @custId

UPDATE CustPositionTaking WITH (ROWLOCK,UPDLOCK)
SET PositionTaking = 2000
WHERE AgentId = 214 AND CustId = @custId

UPDATE CustPositionTaking WITH (ROWLOCK,UPDLOCK)
SET PositionTaking = 1500
WHERE AgentId = 218 AND CustId = @custId

UPDATE CustPositionTaking WITH (ROWLOCK,UPDLOCK)
SET PositionTaking = 500
WHERE AgentId = 222 AND CustId = @custId
/*----- Reset Data-----*/

declare @p9 int
set @p9=0
declare @p10 nvarchar(1000)
set @p10=''
exec Age_Agent_UpdateSetting 
	@ActorAgentId=0
	,@AgentId=206		
	,@BetLimit=''
	,@Discount=''
	,@PositionTaking='
		<ROOT>
			<PositionTaking SportType="1" BetType="1" IsLive="1" MaxUpper="1000" MaxGiven="8500" MinGiven="1500"></PositionTaking>
		</ROOT>'
	,@Language='en-US'
	,@ErrCode=@p9 output
	,@ErrMsg=@p10 output
select @p9, @p10

DECLARE @ActorAgentId INT
SET @ActorAgentId = 0

DECLARE @actorAgentLevel	INT
			,@agentLevel	INT
			,@agentHId		HIERARCHYID
			,@agentId		INT

	SELECT @actorAgentLevel = AgentLevel
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @ActorAgentId

	SELECT @agentId		= AgentId			
	FROM CustInfo WITH (NOLOCK) 
	WHERE CustId	= @custId		

	SELECT @agentLevel	= AgentLevel
			,@agentHId	= AgentHId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId	= @agentId		

	DECLARE @TableAgent TABLE (AgentId INT, AgentLevel INT, Username NVARCHAR(50))
	INSERT INTO @TableAgent
	SELECT ai.AgentId,ai.AgentLevel,ai.Username FROM AgentInfo AS ai WITH (NOLOCK) 
	WHERE @agentHId.IsDescendantOf(ai.AgentHId)	= 1

	SELECT 	apt.AgentId
			,ai.AgentLevel
			,ai.Username
			,capt.MaxUpperPositionTaking
			,apt.MaxGivenPositionTaking
			,apt.MinGivenPositionTaking	
			,cpt.PositionTaking						
	FROM AgentPositionTaking AS apt WITH (NOLOCK)
		INNER JOIN AgentInfo AS ai WITH (NOLOCK)
			ON apt.AgentId = ai.AgentId
		LEFT JOIN @TableAgent AS cai
			ON ai.AgentLevel	= cai.AgentLevel
		LEFT JOIN AgentPositionTaking AS capt WITH (NOLOCK)
			ON apt.SportType	= capt.SportType
			AND apt.BetType		= capt.BetType
			AND apt.IsLive		= capt.IsLive
			AND cai.AgentId		= capt.AgentId
		INNER JOIN CustPositionTaking AS cpt WITH (NOLOCK)
			ON apt.SportType	= cpt.SportType
			AND apt.BetType		= cpt.BetType
			AND apt.IsLive		= cpt.IsLive
			AND apt.AgentId		= cpt.AgentId
		INNER JOIN @TableTempCompare AS ttc
			ON apt.AgentId					= ttc.AgentId
			AND ai.AgentLevel				= ttc.AgentLevel
			AND ai.Username					= ttc.Username
			AND capt.MaxUpperPositionTaking	= ttc.MaxUpperPositionTaking
			AND apt.MaxGivenPositionTaking	= ttc.MaxGivenPositionTaking
			AND apt.MinGivenPositionTaking	= ttc.MinGivenPositionTaking
			AND cpt.PositionTaking			= ttc.PositionTaking
	WHERE ai.AgentLevel BETWEEN @actorAgentLevel AND @agentLevel		
		AND cpt.CustId		= @custId
		AND cpt.SportType	= @SportType
		AND cpt.BetType		= @BetType
		AND cpt.IsLive		= @IsLive

	IF @@RowCount <> 5
		SELECT 'Max Given Share Down' AS ActionName,'FAIL' AS Status
	ELSE
		SELECT 'Max Given Share Down' AS ActionName,'OK' AS Status

/*--------------------------------*/
DELETE @TableTempCompare
INSERT INTO @TableTempCompare VALUES (206,1,'age-ed--0-206',1500,8500,7000,2000)
INSERT INTO @TableTempCompare VALUES (210,2,'age-ed--206-210',1500,7000,0,1000)
INSERT INTO @TableTempCompare VALUES (214,3,'age-ed--210-214',1000,5000,4000,2000)
INSERT INTO @TableTempCompare VALUES (218,4,'age-ed--214-218',1000,3000,1000,1500)
INSERT INTO @TableTempCompare VALUES (222,5,'age-ed--218-222',1500,1500,0,500)

set @p9=0
set @p10=''
exec Age_Agent_UpdateSetting 
	@ActorAgentId=0
	,@AgentId=206		
	,@BetLimit=''
	,@Discount=''
	,@PositionTaking='
		<ROOT>
			<PositionTaking SportType="1" BetType="1" IsLive="1" MaxUpper="1500" MaxGiven="8500" MinGiven="7000"></PositionTaking>
		</ROOT>'
	,@Language='en-US'
	,@ErrCode=@p9 output
	,@ErrMsg=@p10 output
select @p9, @p10

SET @ActorAgentId = 0

	SELECT @actorAgentLevel = AgentLevel
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @ActorAgentId

	SELECT @agentId		= AgentId			
	FROM CustInfo WITH (NOLOCK) 
	WHERE CustId	= @custId		

	SELECT @agentLevel	= AgentLevel
			,@agentHId	= AgentHId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId	= @agentId		

	DELETE @TableAgent
	INSERT INTO @TableAgent
	SELECT ai.AgentId,ai.AgentLevel,ai.Username FROM AgentInfo AS ai WITH (NOLOCK) 
	WHERE @agentHId.IsDescendantOf(ai.AgentHId)	= 1

	SELECT 	apt.AgentId
			,ai.AgentLevel
			,ai.Username
			,capt.MaxUpperPositionTaking
			,apt.MaxGivenPositionTaking
			,apt.MinGivenPositionTaking	
			,cpt.PositionTaking						
	FROM AgentPositionTaking AS apt WITH (NOLOCK)
		INNER JOIN AgentInfo AS ai WITH (NOLOCK)
			ON apt.AgentId = ai.AgentId
		LEFT JOIN @TableAgent AS cai
			ON ai.AgentLevel	= cai.AgentLevel
		LEFT JOIN AgentPositionTaking AS capt WITH (NOLOCK)
			ON apt.SportType	= capt.SportType
			AND apt.BetType		= capt.BetType
			AND apt.IsLive		= capt.IsLive
			AND cai.AgentId		= capt.AgentId
		INNER JOIN CustPositionTaking AS cpt WITH (NOLOCK)
			ON apt.SportType	= cpt.SportType
			AND apt.BetType		= cpt.BetType
			AND apt.IsLive		= cpt.IsLive
			AND apt.AgentId		= cpt.AgentId
		INNER JOIN @TableTempCompare AS ttc
			ON apt.AgentId					= ttc.AgentId
			AND ai.AgentLevel				= ttc.AgentLevel
			AND ai.Username					= ttc.Username
			AND capt.MaxUpperPositionTaking	= ttc.MaxUpperPositionTaking
			AND apt.MaxGivenPositionTaking	= ttc.MaxGivenPositionTaking
			AND apt.MinGivenPositionTaking	= ttc.MinGivenPositionTaking
			AND cpt.PositionTaking			= ttc.PositionTaking
	WHERE ai.AgentLevel BETWEEN @actorAgentLevel AND @agentLevel		
		AND cpt.CustId		= @custId
		AND cpt.SportType	= @SportType
		AND cpt.BetType		= @BetType
		AND cpt.IsLive		= @IsLive

	IF @@RowCount <> 5
		SELECT 'Min Given Share Up' AS ActionName,'FAIL' AS Status
	ELSE
		SELECT 'Min Given Share Up' AS ActionName,'OK' AS Status