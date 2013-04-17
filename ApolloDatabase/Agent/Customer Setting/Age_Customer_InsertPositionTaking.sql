USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_InsertPositionTaking]    Script Date: 4/17/2013 2:54:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_InsertPositionTaking]
	@CustId				INT,
	@AgentId			INT,
	@PositionTaking		VARCHAR(MAX)	= '',
	@Creator			INT				= NULL,
	@LogDate			DATETIME		= NULL,
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsg				NVARCHAR(1000)	= ''		OUTPUT 			
AS

/**
 * Created by	: Kos
 * Date			: 20130302
 * Task			: Insert customer position taking
 * DB			: APL.CustDB
 * Revisions	:
 *	• 20130417@Edward	: Write log and add @Creator, @LogDate 
 * Parameters:
 *	• @PositionTaking : 
		<ROOT>
			<PositionTaking SportType="4" BetType="4" IsLive="1" PT="10" ></PositionTaking>
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
		PT SMALLINT)	

	-- For read xml
	DECLARE @DocHandler int

	EXEC sp_xml_preparedocument @DocHandler OUTPUT, @PositionTaking

	INSERT INTO @PositionTakingTable (
		SportType,
		BetType,
		IsLive,
		PT)			
	SELECT 			
		Data.SportType,
		Data.BetType,
		Data.IsLive,
		Data.PT
	FROM OPENXML (@DocHandler, '/ROOT/PositionTaking',1) 
	WITH (			
		SportType		SMALLINT,
		BetType			SMALLINT,				
		IsLive			BIT,
		PT				SMALLINT				
	) AS Data

	EXEC sp_xml_removedocument @DocHandler
	-- end read xml

	-- Validate data

	-- Insert parent position taking data
	INSERT INTO dbo.CustPositionTaking
	(
		CustId,
		AgentId,
		SportType,
		BetType,
		IsLive,
		PositionTaking
	)
	SELECT
		@CustId,
		@AgentId,
		SportType,
		BetType,
		IsLive,
		PT
	FROM @PositionTakingTable

	-- Insert parent upline position taking data
	
	SET @xml = (
		SELECT SportType	AS '@s' 
				,BetType	AS '@b'
				,IsLive		AS '@i'
				,PT			AS '@p'				
		FROM @PositionTakingTable
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

	SET @endRun		= GETDATE()  
	SET @duration	= DATEDIFF(millisecond, @startRun, @endRun) 

	IF @LogDate IS NULL
		SET @LogDate = GETDATE()	

	EXEC LogDB.dbo.Age_LogRunSp_Insert
		@UserId			= @Creator,
		@SPName			= 'Age_Customer_InsertPositionTaking',
		@LogDate		= @LogDate,
		@ObjectId		= @CustId,
		@ObjectTypeId	= 2,			--Object type : Customer						
		@Duration		= @Duration,
		@Data			= @logSPData,
		@OldData		= @logSPDataOld		   
END
