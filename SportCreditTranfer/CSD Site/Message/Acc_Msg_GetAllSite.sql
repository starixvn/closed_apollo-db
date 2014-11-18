USE [MsgDB]
GO
/****** Object:  StoredProcedure [dbo].[Acc_Msg_GetAllSite]    Script Date: 2/12/2014 11:31:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[Acc_Msg_GetAllSite]
AS
/*
* Created by	: Patrick
* Date			: 20131112
* Task			: Get site info for agent & member site
* DB			: SVRMSG/MsgDB
* Parameters:
* Test string:
	exec dbo.Acc_Msg_GetAllSite
* Revisions	:
	20140212@Patrick	: Change member site to Apollo site
*/
BEGIN
	SET NOCOUNT ON
	SELECT SiteId, SiteName
	FROM dbo.MsgSite WITH(NOLOCK)
	WHERE SiteId IN ('3000000', '4100200')
END
