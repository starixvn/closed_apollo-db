USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_InsertPositionTaking3rd]    Script Date: 3/29/2013 10:09:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_InsertPositionTaking3rd]
	@AgentId			INT,
	@PositionTaking		VARCHAR(MAX)	= '',
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsg				NVARCHAR(1000)	= ''		OUTPUT 			
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Insert agent position taking 3rd
 * DB			: APL.CustDB
 * Revisions	:
 *	• 20130301@Kos		: Implement
 * Parameters:
 *	•	@PositionTaking : 
		<ROOT>
			<ROOT><PositionTaking SportType="4" BetType="4" IsLive="1" Preset="10" Max="1" Min="1"></PositionTaking></ROOT>
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
	INSERT INTO dbo.AgentPositionTaking3rd
	(
		AgentId,
		SportType,
		BetType,
		IsLive,
		PresetPositionTaking,
		MaxPositionTaking,
		MinPositionTaking
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
	   
END
