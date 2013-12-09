USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_UpdatePositionTakingMultiple]    Script Date: 8/9/2013 11:13:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
DECLARE	@return_value int,
		@ErrCode int,
		@ErrMsg nvarchar(1000)

EXEC	@return_value = [dbo].[Age_Customer_UpdatePositionTakingMultiple]
		@ActorAgentId = 206,
		@AgentId = 226,
		@CustId = 128465,
		@PositionTaking = N'<ROOT><PositionTaking SportType="1" BetType="1" IsLive="0" PT="5000" ></PositionTaking></ROOT>',		
		@Language = NULL,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT

SELECT	@ErrCode as N'@ErrCode',
		@ErrMsg as N'@ErrMsg'

SELECT	'Return Value' = @return_value

GO

*/

ALTER PROCEDURE [dbo].[Age_Customer_UpdatePositionTakingMultiple]
	@ActorAgentId		INT				= NULL,
	@AdminId			INT				= NULL,
	@AgentId			INT,
	@CustIds			VARCHAR(MAX),
	@PositionTaking		VARCHAR(MAX)	= '',
	@Language			VARCHAR(5)		= 'en-US',
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsg				NVARCHAR(MAX)	= ''		OUTPUT
AS

/**
 * Created by	: Edward
 * Date			: 20130809
 * Task			: Update customer position taking multiple
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	• 
 * Parameters:
 * • @AgentID			: Parent agent ID
 * • @PositionTaking	: 
 *		<ROOT>
 *			<PositionTaking SportType="4" BetType="4" IsLive="1" PT="10" ></PositionTaking>
 *		</ROOT>
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	DECLARE @TempCustId			INT
			,@TempUsername		NVARCHAR(50)
			,@TempErrMsg		NVARCHAR(1000)
			,@TempSuccessMsg	NVARCHAR(1000)
				
	DECLARE @TableCust TABLE (CustId INT, Username NVARCHAR(50))

	INSERT INTO @TableCust(CustId, Username)
	SELECT val, ci.Username 
	FROM dbo.StrSplit(@CustIds,',')
		INNER JOIN CustInfo AS ci WITH (NOLOCK) ON CONVERT(INT,val) = ci.CustId	

	WHILE EXISTS ( SELECT TOP(1) * FROM @TableCust)
		BEGIN
			SELECT TOP(1) @TempCustId	= CustId 
						,@TempUsername	= Username
			FROM @TableCust

			EXEC Age_Customer_UpdatePositionTaking @ActorAgentId, @AdminId, @AgentId, @TempCustId, @PositionTaking, @Language, @ErrCode OUTPUT, @TempErrMsg OUTPUT	
					
			IF @TempErrMsg IS NOT NULL
				SET @ErrMsg = @ErrMsg + @TempUsername + ' : ' + @TempErrMsg + ';'
			ELSE
				SET @TempSuccessMsg = @TempUsername + ';'

			DELETE @TableCust WHERE CustId = @TempCustId
		END

	SET @ErrMsg = @ErrMsg + '#' + @TempSuccessMsg
END
