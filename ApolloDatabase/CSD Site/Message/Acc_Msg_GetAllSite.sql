IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Acc_Msg_GetAllSite')
	DROP PROC dbo.Acc_Msg_GetAllSite
GO
CREATE PROC dbo.Acc_Msg_GetAllSite
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

*/
BEGIN
	SET NOCOUNT ON
	SELECT SiteId, SiteName
	FROM dbo.MsgSite WITH(NOLOCK)
	WHERE SiteId IN ('3000000', '4100000')
END
GO
GRANT EXECUTE ON [dbo].[Acc_Msg_GetAllSite] TO [aplweb]
GO
