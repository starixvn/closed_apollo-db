USE [MsgDB]
GO
/****** Object:  StoredProcedure [dbo].[Dot_Msg_HasPriMessage24]    Script Date: 6/17/2013 3:15:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Dot_Msg_HasPriMessage24]
	@TargetId	INT,
	@IsAgent	BIT		= 1,
	@IsTest		BIT		= 0
AS

/**
 * Created by	: TWTeam
 * Date			: 
 * Task			: 
 * DB			: SVRMSG.MsgDB
 * Revisions	:
 *	• 20120109@Scott(DB07): add condition for new flag column [isDeleted] to filter deleted data.
 *	• 20130405@Edward : Review, add parameter @IsAgent, change parameter from @UserId to @TargetId
 * Parameters:
 *  
 */

BEGIN
	SET NOCOUNT ON;

	DECLARE 
		@MessageID	INT,
		@PostTime	DATETIME

	--If exists
	SELECT TOP 1 
		@MessageID = m.MessageID,
		@PostTime = m.PostTime 
	FROM 
		dbo.Msg AS m WITH (NOLOCK)
		INNER JOIN dbo.MsgTarget AS mt WITH (NOLOCK) ON m.MessageId	= mt.MessageId
	WHERE 
		m.MsgType			= 1
		AND m.isDeleted		= 0
		AND mt.isDeleted	= 0
		AND m.IsSticky		= 0
		AND (@IsTest = 1 OR (@IsTest <> 1 AND m.IsTest = @IsTest))
		AND mt.TargetId		= @TargetId
		AND mt.IsAgent		= @IsAgent
	ORDER BY m.PostTime DESC

	IF @@ROWCOUNT > 0
		SELECT 
			@MessageID AS MessageID, 
			@PostTime AS Posttime
	ELSE
		SELECT 
			0 AS MessageID, 
			NULL AS PostTime
END