---#Step1: Build SP
ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
	@ids varchar(max)
AS
SET NOCOUNT ON
/*
	Created: Sophia
	Date: 20141111
	Task: Insert AgentUser for new function
	DB: SVRTXN/CUSTDB
*/ 

BEGIN
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('AgentUser') AND type = 'U') <> 1
		RETURN

	DECLARE @res AS TABLE (AgentUserId INT)
	DECLARE @splitter CHAR(1), @string VARCHAR(MAX)

	SELECT @splitter = ',', @string = @ids

	IF SUBSTRING (@string, LEN (@string), 1) <> @splitter
		  SET @string= @string+@splitter

	DECLARE @START INT, @word NVARCHAR(4000), @CHARINDEX INT, @i INT
	SET @i=1
	SET @START=1
	SET @CHARINDEX= CHARINDEX( @splitter, @string, @START)
	WHILE (@CHARINDEX <> 0)BEGIN
		SET @word= SUBSTRING( @string, @START, @CHARINDEX - @START)
		SET @START= @CHARINDEX +1
		SET @CHARINDEX= CHARINDEX( @splitter, @string, @START)
		INSERT INTO @res  VALUES(CAST(@word AS INT))
		SET @i=@i+1
	END	
	
	INSERT INTO AgentUserFunction (AgentUserId, FunctionId, AgentId, Policy)
	SELECT	AgentUserID, 22, AgentID, 2 
	FROM	AgentUser WITH (NOLOCK)
	WHERE	AgentUserId IN (SELECT AgentUserId FROM @res) AND IsMaster = 1

	INSERT INTO AgentUserFunction (AgentUserId, FunctionId, AgentId, Policy)
	SELECT	AgentUserID, 22, AgentID, 1 
	FROM	AgentUser WITH (NOLOCK)
	WHERE	AgentUserId IN (SELECT AgentUserId FROM @res) AND IsMaster <> 1

	INSERT INTO AgentUserFunction (AgentUserId, FunctionId, AgentId, Policy)
	SELECT	AgentUserID, 23, AgentID, 1 
	FROM	AgentUser WITH (NOLOCK)
	WHERE	AgentUserId IN (SELECT AgentUserId FROM @res)

END
GO



---- #Step2: Execute

--DECLARE @maxAgentUserId INT
--SELECT @maxAgentUserId = MAX(AgentUserId) FROM AgentUser WITH (NOLOCK) 

CREATE TABLE #temp (AgentUserId INT PRIMARY KEY, IsFinished BIT) 
INSERT INTO #temp (AgentUserId, IsFinished)
SELECT DISTINCT AgentUserId , 0 
FROM   AgentUser WITH (NOLOCK)	


GO

DECLARE @ids VARCHAR(max), @rowcnt INT

WHILE (1 = 1)
BEGIN
	SELECT @ids = ''

	UPDATE TOP(10000) #temp
	SET		@ids = @ids +CASE @ids
							WHEN '' THEN ''
							ELSE ','
						 END + cast(AgentUserId AS VARCHAR(12))
			,IsFinished = 1
	FROM	#temp
	WHERE	IsFinished = 0

	SELECT @rowcnt = @@rowcount

	EXEC [Acc_ExecRep_09] @ids = @ids

	IF @rowcnt < 10000 RETURN

	WAITFOR DELAY '00:00:01'
END



DROP TABLE #temp
GO