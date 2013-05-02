USE [LogDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_LogRunSp_Insert]    Script Date: 4/26/2013 4:59:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_LogRunSp_Insert]  
	@UserId			INT,	
	@SPName			NVARCHAR(50)	= NULL,
	@LogDate		DATETIME,
	@ObjectId		INT				= NULL,
	@ObjectTypeId	INT				= NULL,
	@Duration		INT				= NULL,  
	@Data			NVARCHAR(MAX)	= NULL,
	@OldData		NVARCHAR(MAX)	= NULL	
AS
/**
 * Created: 20130326@Edward
 * Task: Add new log user run sp
 * DB: LogDB
 *  
 * Revisions:     
 * Param's Explanation: 
 *  - @UserId: UserId perform this action  
 *  - @ActionId: Log action ID
 *  
 */
BEGIN

	SET NOCOUNT ON
	
	DECLARE @actionId	INT

	SELECT @actionId = ActionId
	FROM LogAction  WITH(NOLOCK)
	WHERE SPName = @SPName

	IF @ObjectTypeId = 1	-- Agent
		BEGIN
			INSERT INTO RunSpAgent(
				UserId
				,SPName
				,LogDate
				,AgentId
				,ActionId
				,Duration
				,Data
				,OldData)
			VALUES(
				 @UserId
				,@SPName
				,@LogDate
				,@ObjectId
				,@actionId
				,@Duration
				,@Data
				,@OldData
			)
		END

	IF @ObjectTypeId = 2	-- Customer
		BEGIN
			INSERT INTO RunSpCust(
				UserId
				,SPName
				,LogDate
				,AgentId
				,ActionId
				,Duration
				,Data
				,OldData)
			VALUES(
				 @UserId
				,@SPName
				,@LogDate
				,@ObjectId
				,@actionId
				,@Duration
				,@Data
				,@OldData
			)
		END

END