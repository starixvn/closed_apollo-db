
/****** Object:  StoredProcedure [dbo].[WriteLog_UserLog_T]    Script Date: 4/26/2013 4:36:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
ALTER PROCEDURE [dbo].[WriteLog_UserLog_T]
	@UserID int,
	@Doing nvarchar(300)
AS
/*	
	Create: 20120314@Sophia
	Task: Write Log on UserLog_T
	DB: SVRTXN.TransDB
	
	Revisions:
		 
*/
SET NOCOUNT ON
INSERT INTO UserLog_T (UserID, Doing) values (@UserID, @Doing)
GO 


GRANT EXECUTE ON [dbo].[WriteLog_UserLog_T] TO [aplweb]
