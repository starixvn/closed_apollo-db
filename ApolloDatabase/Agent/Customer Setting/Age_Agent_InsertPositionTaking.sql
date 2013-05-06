USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_InsertPositionTaking]    Script Date: 5/6/2013 11:25:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_InsertPositionTaking]
	@AgentId			INT,
	@PositionTaking		VARCHAR(MAX)	= '',
	@Creator			INT				= NULL,	
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsg				NVARCHAR(1000)	= ''		OUTPUT 			
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Insert agent position taking
 * DB			: APL.CustDB
 * Revisions	:
 *	• 20130301@Kos		: Implement
 *	• 20130417@Edward	: Write log and add @Creator, @LogDate
 * Parameters:
 *	• @PositionTaking : 
		<ROOT>
			<PositionTaking SportType="4" BetType="4" IsLive="1" Preset="10" Max="1" Min="1"></PositionTaking>
		</ROOT>
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	-- For write log
    DECLARE @startRun			DATETIME  
			,@endRun			DATETIME  
			,@duration			INT
			,@logSPData			VARCHAR(5000)
			,@logSPDataOld		VARCHAR(5000)			
			,@xml				XML			

	SET @startRun = GETDATE()	

	DECLARE @PositionTakingTable TABLE(
		SportType SMALLINT,
		BetType SMALLINT,
		IsLive	BIT,
		PrePT SMALLINT,
		MaxPT SMALLINT,
		MinPT SMALLINT)	

	DECLARE @DocHandler int

	EXEC sp_xml_preparedocument @DocHandler OUTPUT, @PositionTaking

	INSERT INTO @PositionTakingTable (		
		SportType,
		BetType,
		IsLive,
		PrePT,
		MaxPT,
		MinPT)
	SELECT
		Data.SportType,
		Data.BetType,
		Data.IsLive,
		Data.Preset,
		Data.Max,
		Data.Min
	FROM OPENXML (@DocHandler, '/ROOT/PositionTaking',1) 
	WITH (			
		SportType		SMALLINT,
		BetType			SMALLINT,
		IsLive			BIT,
		Preset			SMALLINT,
		Max				SMALLINT,
		Min				SMALLINT
	) AS Data

	EXEC sp_xml_removedocument @DocHandler
	-- Validate data

	-- Insert data
	INSERT INTO dbo.AgentPositionTaking
	(
		AgentId,
		SportType,
		BetType,
		IsLive,
		MaxUpperPositionTaking,
		MaxGivenPositionTaking,
		MinGivenPositionTaking
	)
	SELECT
		@AgentId,
		SportType,
		BetType,
		IsLive,
		PrePT,
		MaxPT,
		MinPT
	FROM @PositionTakingTable

	SET @xml = (
		SELECT SportType	AS '@s' 
				,BetType	AS '@b'
				,IsLive		AS '@i'
				,PrePT		AS '@p'
				,MaxPT		AS '@ma'
				,MinPT		AS '@mi'
		FROM @PositionTakingTable
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

	SET @endRun		= GETDATE()  
	SET @duration	= DATEDIFF(millisecond, @startRun, @endRun) 	
	
	IF @@Error = 0
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
			@UserId			= @Creator,
			@SPName			= 'Age_Agent_InsertPositionTaking',
			@LogDate		= @startRun,
			@AgentId		= @AgentId,
			@Duration		= @Duration,
			@Data			= @logSPData,
			@OldData		= @logSPDataOld
		END	TRY
		BEGIN CATCH
			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
			@UserId			= @Creator,
			@SPName			= 'Age_Agent_InsertPositionTaking',
			@LogDate		= @startRun,
			@AgentId		= @AgentId,
			@Duration		= @Duration,
			@Data			= @logSPData,
			@OldData		= @logSPDataOld
		END CATCH 
END
