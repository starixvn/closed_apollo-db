USE [MsgDB]
GO
/****** Object:  StoredProcedure [dbo].[Dot_Msg_SetUsrMessage]    Script Date: 6/17/2013 4:10:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

ALTER PROCEDURE [dbo].[Dot_Msg_SetUsrMessage]
	@MessageId	INT,
	@TargetId	INT,
	@IsAgent	BIT,
	@TargetName NVARCHAR(50)	= '',
	@isRead		BIT				= 0,
	@BetTransId	VARCHAR(2000)	= '',
	@PostTime	DATETIME		= NULL ,
	@Creator	INT				= 0
AS

/**
 * Created by	: TWTeam
 * Date			: 
 * Task			: Add/Update target message 
 * DB			: SVRMSG.MsgDB
 * Revisions	:
 *	• 20130405@Kos	:	Review and add parameter @IsAgent
 * Parameters:
 *  
 */

BEGIN
	IF EXISTS (SELECT MessageId FROM dbo.Msg WITH (NOLOCK) WHERE MessageId = @MessageId)
		BEGIN
			IF EXISTS (	SELECT MessageId 
						FROM dbo.MsgTarget WITH (NOLOCK) 
						WHERE 
							MessageId = @MessageId 
							AND TargetId = @TargetId
							AND IsAgent = @IsAgent )
				BEGIN
					-- update
					UPDATE dbo.MsgTarget WITH (ROWLOCK, UPDLOCK)
					SET	
						TargetName = @TargetName, 
						BetTransId = @BetTransId, 
						isDeleted = 0
					WHERE 
						MessageId = @MessageId 
						AND TargetId = @TargetId
						AND IsAgent = @IsAgent
				END
			ELSE
				BEGIN
					-- insert
					INSERT dbo.MsgTarget(
						MessageId, 
						TargetId, 
						IsAgent,
						TargetName, 
						isRead, 
						BetTransId,
						PostTime		-- messagetype: for old version
					) 
					VALUES (
						@MessageId, 
						@TargetId, 
						@IsAgent,
						@TargetName, 
						@isRead, 
						@BetTransId,
						@PostTime
					)
				END
		END
END

