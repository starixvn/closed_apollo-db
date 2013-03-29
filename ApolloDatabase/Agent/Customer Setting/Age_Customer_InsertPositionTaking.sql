USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_InsertPositionTaking]    Script Date: 3/29/2013 10:43:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_InsertPositionTaking]
	@CustId				INT,
	@AgentId			INT,
	@PositionTaking		VARCHAR(MAX)	= '',
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsg				NVARCHAR(1000)	= ''		OUTPUT 			
AS

/**
 * Created by	: Kos
 * Date			: 20130302
 * Task			: Insert customer position taking
 * DB			: APL.CustDB
 * Revisions	:
 *	• 
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
	   
END
