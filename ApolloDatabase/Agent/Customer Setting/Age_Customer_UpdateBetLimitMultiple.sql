USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_UpdateBetLimitMultiple]    Script Date: 8/9/2013 9:29:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Customer_UpdateBetLimitMultiple]
	@ActorAgentId	INT				= NULL,
	@AdminId		INT				= NULL,
	@CustIds		VARCHAR(MAX),	
	@BetLimit		VARCHAR(MAX)	= '',
	@Language		VARCHAR(5)		= 'en-US',
	@ErrCode		INT				= 0			OUTPUT,
	@ErrMsg			NVARCHAR(MAX)	= ''		OUTPUT
AS

/**
 * Created by	: Edward
 * Date			: 20130808
 * Task			: Update customer bet limit	multiple
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	• 20131707@Edward	: Add parameter @AdminId for write log
 * Parameters:
 *	• @BetLimit : 
		<ROOT>
			<BetLimit SportType="4" BetType="4" Min="1" Max="1" MaxPerMatch="1"></BetLimit>
		</ROOT>
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	DECLARE @TempCustId		INT
			,@TempErrMsg	NVARCHAR(1000)
				
	DECLARE @TableCust TABLE (CustId INT)

	INSERT INTO @TableCust(CustId)
	SELECT val FROM dbo.StrSplit(@CustIds,',')

	WHILE EXISTS ( SELECT TOP(1) * FROM @TableCust)
		BEGIN
			SELECT TOP(1) @TempCustId = CustId FROM @TableCust

			EXEC Age_Customer_UpdateBetLimit @ActorAgentId, @AdminId, @TempCustId, @BetLimit, @Language, @ErrCode OUTPUT, @TempErrMsg OUTPUT

			SET @ErrMsg = @ErrMsg + ';' + @TempErrMsg

			DELETE @TableCust WHERE CustId = @TempCustId
		END
END
