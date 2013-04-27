 
/****** Object:  StoredProcedure [dbo].[WriteLog_UserLog_P]    Script Date: 4/26/2013 4:33:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
ALTER PROCEDURE [dbo].[WriteLog_UserLog_P]
	@UserID int,
	@Doing nvarchar(300)
AS
/*	
	Create: 20120314@Sophia
	Task: Write Log on UserLog_P
	DB: SVRPRO.ProdDB
	
	Revisions:
		 
*/
SET NOCOUNT ON
INSERT INTO UserLog_P (UserID, Doing) values (@UserID, @Doing)

GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_P] TO [aplweb]