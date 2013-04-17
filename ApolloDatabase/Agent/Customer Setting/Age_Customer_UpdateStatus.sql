USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_UpdateStatus]    Script Date: 4/17/2013 3:11:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_UpdateStatus]
	@CustId		INT,	
	@Type		TINYINT,
	@Status		TINYINT,
	@Modifier	INT				= NULL,
	@LogDate	DATETIME		= NULL,
	@ErrCode	INT				= 0			OUTPUT,
	@ErrMsg		NVARCHAR(1000)	= ''		OUTPUT	
AS

/**
 * Created by	: Kos
 * Date			: 20130415
 * Task			: Update customer status
 * DB			: APL.CustDB
 * Revisions	:
 *	• 
 * Parameters:
 *	• @Type		:	1 : Account status
 *					2 : Bet status
 *	• @Status	:	1 : Active
 *					2 : Stopped
 *					3 : Locked
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

	SET @xml = (
		SELECT	@Type		AS '@t'
				,Status		AS '@as'
				,BetStatus	AS '@bs'
		FROM CustInfo WITH (NOLOCK)
		WHERE CustId = @CustId
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPDataOld = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

	IF @Type = 1  			-- Account status
		BEGIN
			UPDATE CustInfo
			SET Status = @Status
			WHERE 
				CustId = @CustId
				AND Status <> @Status

			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 1207, 
						@ErrMsg = 'Failed to update customer status [CustId = ' + COALESCE(CAST(@CustId AS VARCHAR(10)), SPACE(1)) + ']'
					RETURN
				END	
		END
	ELSE IF @Type = 2		-- Bet status
		BEGIN
			UPDATE CustInfo
			SET BetStatus = @Status
			WHERE 
				CustId = @CustId
				AND BetStatus <> @Status

			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 1207, 
						@ErrMsg = 'Failed to update customer status [CustId = ' + COALESCE(CAST(@CustId AS VARCHAR(10)), SPACE(1)) + ']'
					RETURN
				END	
		END
	
	SET @xml = (
		SELECT	@Type		AS '@t'
				,Status		AS '@as'
				,BetStatus	AS '@bs'
		FROM CustInfo WITH (NOLOCK)
		WHERE CustId = @CustId
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

	SET @endRun		= GETDATE()  
	SET @duration	= DATEDIFF(millisecond, @startRun, @endRun) 

	IF @LogDate IS NULL
		SET @LogDate = GETDATE()	

	EXEC LogDB.dbo.Age_LogRunSp_Insert
		@UserId			= @Modifier,
		@SPName			= 'Age_Customer_UpdateStatus',
		@LogDate		= @LogDate,
		@ObjectId		= @CustId,
		@ObjectTypeId	= 2,			--Object type : Customer						
		@Duration		= @Duration,
		@Data			= @logSPData,
		@OldData		= @logSPDataOld	
END
