USE [RepDB]
GO
/****** Object:  UserDefinedFunction [dbo].[strSplit_Key]    Script Date: 4/26/2013 12:46:21 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION  [dbo].[strSplit_Key] (
	@string		NVARCHAR(4000), 
	@splitter	CHAR(1)
)
RETURNS @res TABLE (val INT PRIMARY KEY)
AS
/**
 * Created by	: Quinn
 * Date			: 20130301
 * Task			: 
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	•
 * Parameters:
 *  
 */
BEGIN
	SET @string = ISNULL(@string,'')
	IF SUBSTRING (@string, LEN(@string), 1) <> @splitter
		SET @string = @string + @splitter

	DECLARE 
		@start		INT,
		@word		NVARCHAR(4000), 
		@charindex	INT, 
		@i			INT

	SET @i = 1
	SET @start = 1
	SET @charindex = CHARINDEX(@splitter, @string, @start)

	WHILE (@charindex <> 0)
		 BEGIN
			SET @word = SUBSTRING(@string, @start, @charindex - @start)
			SET @start = @charindex + 1
			SET @charindex = CHARINDEX( @splitter, @string, @start)

			INSERT INTO @res VALUES (@word)

			SET @i = @i + 1
		 END

	RETURN
END

