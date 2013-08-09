USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_UpdateDiscountMultiple]    Script Date: 8/9/2013 9:29:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Customer_UpdateDiscountMultiple]
	@ActorAgentId	INT				= NULL,
	@AdminId		INT				= NULL,
	@CustIds		VARCHAR(MAX),	
	@UGroup			VARCHAR(3),
	@Discount		VARCHAR(MAX)	= '',
	@Language		VARCHAR(5)		= 'en-US',
	@ErrCode		INT				= 0			OUTPUT,
	@ErrMsg			NVARCHAR(MAX)	= ''		OUTPUT
AS

/**
 * Created by	: Edward
 * Date			: 20130808
 * Task			: Update customer discount multiple
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	• 20131707@Edward	: Add parameter @AdminId for write log
 * Parameters:
 *	• @Discount :
		<ROOT>
			<Discount SportType="4" BetType="4" Discount="1" ></Discount>
		</ROOT>		
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

			EXEC Age_Customer_UpdateDiscount @ActorAgentId, @AdminId, @TempCustId, @UGroup, @Discount, @Language, @ErrCode OUTPUT, @TempErrMsg OUTPUT	

			SET @ErrMsg = @ErrMsg + ';' + @TempErrMsg

			DELETE @TableCust WHERE CustId = @TempCustId
		END
END
