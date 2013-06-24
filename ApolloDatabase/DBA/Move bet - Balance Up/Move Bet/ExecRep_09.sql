
/****** Object:  StoredProcedure [dbo].[ExecRep_09]    Script Date: 05/20/2013 22:57:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ExecRep_09]
	@CustIDs varchar(max) = '',
	@IsAgent BIT = NULL,
	@Winlostdate smalldatetime,
	@parlay tinyint = 0
AS
/*
Created by:Sophia
Date: 20130521
Task: Delete bettrans/bettrans_Agent/bettransm for whole day of @winlostdate
DB: SVRTXN.TransDB
Revisions:
     
    
 */

SET NOCOUNT ON
 
IF @parlay = 29
BEGIN

	if exists (select * from dbo.sysobjects where name = 'betParlayResult')
	BEGIN
		DELETE FROM dbo.betParlayResult
		WHERE winlostdate <= @winlostdate

		DELETE FROM dbo.BetParlayResult_Agent
		WHERE winlostdate <= @winlostdate
		
		DELETE FROM dbo.betParlayDetail
		WHERE winlostdate <= DATEADD(day, -14, @winlostdate)
	END
	
	RETURN

END

 
IF @parlay = 1
BEGIN
	Declare @rc int, @rn int, @rn2 int
	Declare @matchid int
	CREATE TABLE #m (rn int PRIMARY KEY IDENTITY(1,1), matchid int)

	INSERT INTO #m (matchid)
	SELECT DISTINCT m.matchid
	FROM dbo.bettransm b with (nolock)
		INNER JOIN dbo.match m with (nolock) ON b.matchid = m.matchid
	WHERE winlostdate = @winlostdate
	SET @rn2 = @@ROWCOUNT
	
	SET @rn = 1

	NextMatchIDm:
	SELECT @matchid = matchid FROM #m WHERE rn = @rn
	IF @@ROWCOUNT = 0 GOTO NoMoreMatchIDm
	
	DELETE FROM bettransm WHERE matchid = @matchid --AND winlostdate = @winlostdate
	DELETE FROM #m WHERE rn = @rn
	SET @rn = @rn + 1
	GOTO NextMatchIDm
	
	NoMoreMatchIDm:
	DELETE FROM bettransm WHERE winlostdate = @winlostdate
	
	DROP TABLE #m
END
ELSE
BEGIN 
	IF @IsAgent = 0
	DELETE FROM bettrans WHERE CustId IN (select val FROM StrSplit_key(@CustIds,',')) AND winlostdate = @winlostdate AND bettype < 19999
	ELSE 
	DELETE FROM bettrans_Agent WHERE AgentId IN (select val FROM StrSplit_key(@CustIds,',')) AND winlostdate = @winlostdate AND bettype < 19999

END