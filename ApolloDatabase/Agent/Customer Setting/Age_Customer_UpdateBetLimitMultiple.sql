USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_UpdateBetLimitMultiple]    Script Date: 8/9/2013 11:12:30 AM ******/
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
	
	DECLARE @TempCustId			INT
			,@TempUsername		NVARCHAR(50)
			,@TempErrMsg		NVARCHAR(1000)
			,@TempSuccessMsg	NVARCHAR(1000)
				
	DECLARE @TableCust TABLE (CustId INT, Username NVARCHAR(50))

	INSERT INTO @TableCust(CustId, Username)
	SELECT val, ci.Username 
	FROM dbo.StrSplit(@CustIds,',')
		INNER JOIN CustInfo AS ci WITH (NOLOCK) ON val = ci.CustId			

	WHILE EXISTS ( SELECT TOP(1) * FROM @TableCust)
		BEGIN
			SELECT TOP(1) @TempCustId	= CustId 
						,@TempUsername	= Username
			FROM @TableCust

			EXEC Age_Customer_UpdateBetLimit @ActorAgentId, @AdminId, @TempCustId, @BetLimit, @Language, @ErrCode OUTPUT, @TempErrMsg OUTPUT

			IF @TempErrMsg IS NOT NULL
				SET @ErrMsg = @ErrMsg + @TempUsername + ' : ' + @TempErrMsg + ';'
			ELSE
				SET @TempSuccessMsg = @TempUsername + ';'

			DELETE @TableCust WHERE CustId = @TempCustId
		END

	SET @ErrMsg = @ErrMsg + '#' + @TempSuccessMsg
END
