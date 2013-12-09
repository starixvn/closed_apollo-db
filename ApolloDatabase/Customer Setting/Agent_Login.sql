USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Agent_Login]    Script Date: 3/29/2013 10:46:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Agent_Login]
	@UserName		VARCHAR(50) = '' OUTPUT,
	@AgentId		INT = 0 OUTPUT,
	@AgentLevel		SMALLINT = 0 OUTPUT,
	@Currency		TINYINT = 0	OUTPUT,
	@IsMaster		BIT = false OUTPUT,	
	@PageAccess		VARCHAR(50) = '' OUTPUT,
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			VARCHAR(4000) = '' OUTPUT

	


AS
BEGIN


	
	IF EXISTS(SELECT 1 FROM AgentUser WITH(NOLOCK) WHERE Username = @UserName)
	BEGIN		
		SELECT 
		@UserName = ai.Username,
		@AgentId = au.AgentId,
		@AgentLevel = ai.AgentLevel,		
		@Currency = ai.Currency,
		@IsMaster = au.IsMaster,
		@PageAccess = au.PageAccess,		
		@ErrCode = 0,
		@ErrMsg = ''		 
		FROM AgentUser au WITH(NOLOCK) INNER JOIN AgentInfo ai WITH(NOLOCK) ON au.AgentId = ai.AgentId
		WHERE au.Username = @UserName
	END
	ELSE
	BEGIN			

		SELECT @ErrCode = 106, @ErrMsg = 'Wrong username or password'
	END
END
