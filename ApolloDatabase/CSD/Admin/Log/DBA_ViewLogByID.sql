USE [bodb_NAPLOG]
GO
/****** Object:  StoredProcedure [dbo].[DBA_ViewLogByID]    Script Date: 6/21/2013 1:47:05 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[DBA_ViewLogByID]
	@LogId bigint
AS
/*  
 * Created: 20121128@Viet
 * Task : Get execute SP log by log ID
 * DB: bodb_NAPLOG
 *  
 * Revisions:     
 * Param's Explanation: 
*/
BEGIN
	SET NOCOUNT ON

	declare @actionid smallint, @data varchar(max), @olddata varchar(max)

	SELECT @actionid =actionid, @data = data, @olddata = olddata
	FROM dbo.NAPLOG_RUNSP_Detail WITH(NOLOCK)
	WHERE ID = @LogId

	DECLARE @Items TABLE (name varchar(30), alias varchar(2), isSub bit)
	DECLARE @_XML XML, @s1 varchar(max), @s2 varchar(max)

	SELECT @s1 = isnull(Items,'')
		  ,@s2 = isnull(SubItems, '')		  
	FROM dbo.NAPLog_Action WITH(NOLOCK)
	WHERE actionID = @actionid

	if @s1 = '' RETURN
	
	DECLARE @Tsql nvarchar(4000)

	-- main
	SET @Tsql = dbo.f_GEN_Tsql(@s1, @data)
	EXEC sp_executesql @Tsql

	IF @s2 <> '' -- sub
	BEGIN
		SET @Tsql = dbo.f_GEN_Tsql(@s2, @data)
		EXEC sp_executesql @Tsql
	END

	-- main old
	SET @Tsql = dbo.f_GEN_Tsql(@s1, @olddata)
	EXEC sp_executesql @Tsql

	IF @s2 <> '' -- sub old
	BEGIN
		SET @Tsql = dbo.f_GEN_Tsql(@s2, @olddata)
		EXEC sp_executesql @Tsql
	END	
END
