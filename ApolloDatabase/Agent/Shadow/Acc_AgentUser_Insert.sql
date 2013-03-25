USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Acc_AgentUser_Insert]    Script Date: 3/8/2013 9:28:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[Acc_AgentUser_Insert]
	@AgentUserId			INT,
	@AgentId				INT,	
	@Username				VARCHAR(50),
	@IsMaster				BIT,	
	@PageAccess				VARCHAR(50),		
	@CreateDate				DATETIME,
	@Closed					BIT,			
	@Creator				INT,
	@ErrCode				INT				= 0			OUTPUT,
	@ErrMsg					NVARCHAR(1000)	= ''		OUTPUT 
AS

/**
 * Created by	: Edward
 * Date			: 20130304
 * Task			: Add new agent user information
 * DB			: SVRAGE.CustDB
 * Revisions	:
 *	• 
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON	

	---- Insert AgentUser isMaster = true
	INSERT INTO AgentUser(
		AgentUserId,
		AgentId,
		Username,
		IsMaster,
		PageAccess,
		CreateDate,
		Closed,
		Creator,
		LoginCount)
	VALUES(
		@AgentUserId,
		@AgentId,
		@Username,
		@IsMaster,
		@PageAccess,
		@CreateDate,
		@Closed,
		@Creator,
		0)

	---- Not support for multiple language
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 1, 
				@ErrMsg = 'Failed to insert agent user [AgentUserId = ' + COALESCE(CAST(@AgentUserId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END
		
END	
