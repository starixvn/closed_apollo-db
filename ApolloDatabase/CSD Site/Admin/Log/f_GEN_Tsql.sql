USE [bodb_NAPLOG]
GO
/****** Object:  UserDefinedFunction [dbo].[f_GEN_Tsql]    Script Date: 6/21/2013 1:50:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[f_GEN_Tsql] (@template varchar(1000), @data varchar(MAX))
	RETURNs varchar(4000)
AS
BEGIN
	DECLARE @Tsql nvarchar(4000), @_XML XML, @xmlpath varchar(30)
	DECLARE @Items TABLE (name varchar(30), alias varchar(2))	
	
	SET @_XML = CONVERT(XML, @template)	

	INSERT INTO @Items (name, alias) 
	SELECT	
		T.C.value('./@item', 'varchar(100)'), 
		T.C.value('./@alias', 'varchar(100)')
	from @_XML.nodes('/root/row') as [T](C) --T: table, C: column
	
	SELECT	@xmlpath = T.C.value('./@path', 'varchar(100)')
	from @_XML.nodes('/root/xml') as [T](C) --T: table, C: column

	SET @Tsql = ''
	SELECT @Tsql = @Tsql + SPACE(4)+',T.C.value(''./@'+alias+''', ''varchar(1000)'') as '+name+''+char(13)
	FROM @Items	

	SET @Tsql = 'DECLARE @xml xml'+char(13)
		+ 'SET @xml = '''+@data +''''+char(13)+char(13)		
		+ 'SELECT ' + char(13)
		+ STUFF(@Tsql,5,1,'') 
		+ 'FROM @xml.nodes(''/'+@xmlpath+''') as [T](C)'+char(13)		
	RETURN @Tsql
		
END