USE [LogDB]
GO
/****** Object:  StoredProcedure [dbo].[WriteLog_Settlement_Checking]    Script Date: 4/26/2013 4:43:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 ALTER PROCEDURE [dbo].[WriteLog_Settlement_Checking]
	@UserID int, 
	@MatchID int, 
	@KeyID tinyint,
	@ActionID int=0, 	
    @Remark VARCHAR(500) = ''
AS
/*
Creator: Sophia
Date: 20130317
DB: SVRLOG.LOGDB
Task: Insert LOGS for checking a match which cannot settle due to it is marked as "Being calculated"

Revision:

*/

SET NOCOUNT ON

INSERT INTO dbo.Settlement_Checking
(	
	UserID,
	MatchID,
	KeyID,
	ActionID,	
	Remark
) 
VALUES
(	
	@UserID,
	@MatchID,
	@KeyID,
	@ActionID,	
    @Remark
)



GO
GRANT EXECUTE ON [dbo].[WriteLog_Settlement_Checking] TO [aplweb]

