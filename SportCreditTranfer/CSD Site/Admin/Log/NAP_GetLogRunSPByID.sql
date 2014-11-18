USE [bodb_NAPLOG]
GO
/****** Object:  StoredProcedure [dbo].[NAP_GetLogRunSPByID]    Script Date: 6/21/2013 1:47:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_GetLogRunSPByID]
	@LogId bigint
AS
/*  
 * Created: 20121128@Viet
 * Task : Get execute SP log by log ID
 * DB: bodb_NAP
 *  
 * Revisions:     
 * Param's Explanation: 
*/
BEGIN
	SET NOCOUNT ON

--	SELECT * 
--	FROM LogExecSp WITH (NOLOCK)
--	WHERE Id = @LogId
	-----------------------
--	declare @logid bigint
--	set @logid = 2
	-----------------------

	SELECT L.*, LD.Data, LD.OldData, LA.Items, LA.SubItems, Language
	FROM dbo.NAPLog_RUNSP AS L WITH (NOLOCK)
		INNER JOIN dbo.NAPLOG_RUNSP_Detail LD WITH (NOLOCK) ON L.ID = LD.ID
		INNER JOIN dbo.NAPLog_Action LA WITH (NOLOCK) ON L.actionID = LA.actionID
		INNER JOIN dbo.NAPLog_Language LG WITH(NOLOCK) ON L.langid = LG.langID
	WHERE L.ID = @LogId	
END

