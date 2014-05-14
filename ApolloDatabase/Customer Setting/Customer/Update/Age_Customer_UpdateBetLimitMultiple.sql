USE [CustDB]
GO
ALTER PROCEDURE [dbo].[Age_Customer_UpdateBetLimitMultiple]
	@ActorAgentId	INT				= NULL,
	@AdminId		INT				= NULL,
	@CustIds		VARCHAR(MAX),	
	@BetLimit		VARCHAR(MAX)	= '',
	@Language		VARCHAR(5)		= 'en-US',
	@AllowUpdateMinBet BIT			= 0,
	@ErrCode		INT				= 0			OUTPUT,
	@ErrMsg			NVARCHAR(MAX)	= ''		OUTPUT
AS

/**
 * Created by	: Edward
 * Date			: 20130808
 * Task			: Update customer bet limit	multiple
 * DB			: SVRCUST/CustDB
 * Revisions	:
 *	• 20131707@Edward	: Add parameter @AdminId for write log
 *	• 20140224@Patrick	: Add more param: Allow update min bet when called from CSD site
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
	
	DECLARE @TempCustId			INT
			,@TempUsername		NVARCHAR(50)	= ''			
			,@TempSuccessMsg	NVARCHAR(1000)	= ''
			,@TempErrMsg		NVARCHAR(1000)	= NULL
				
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

			EXEC Age_Customer_UpdateBetLimit
				@ActorAgentId = @ActorAgentId
				, @AdminId = @AdminId
				, @CustId = @TempCustId
				, @BetLimit = @BetLimit
				, @Language = @Language
				, @AllowUpdateMinBet = @AllowUpdateMinBet
				, @ErrCode = @ErrCode OUTPUT
				, @ErrMsg = @TempErrMsg OUTPUT

					 
			IF @TempErrMsg IS NOT NULL									
				SET @ErrMsg = ISNULL(@ErrMsg,'') + ISNULL(@TempUsername,'') + ' : ' + ISNULL(@TempErrMsg,'') + ';'							
			ELSE
				SET @TempSuccessMsg = ISNULL(@TempSuccessMsg,'') + ISNULL(@TempUsername,'') + ';'			
			
			DELETE @TableCust WHERE CustId = @TempCustId
		END
	
	SET @ErrMsg += '##' + @TempSuccessMsg
END

GO

GRANT EXECUTE ON [dbo].[Age_Customer_UpdateBetLimitMultiple] TO [aplweb] AS [dbo]
GO


