
/****** Object:  StoredProcedure [dbo].[ExecRep_02]    Script Date: 05/20/2013 22:58:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ExecRep_02]
	@winlostdate date = NULL,
	@Command varchar(20) = 'ALL_DB'
AS
/*
	Created by: Sophia
	Date: 20130604
	Task: Clear data bettrans14, bettransm14, Sum_WinLoss_Cust, Sum_WinLoss_Agent
	DB: SVRTXN.TRANSDB
	Orginal SP: bodb02.ExecRep_02
	Revisions:
		
*/

SET NOCOUNT ON
-- call from Joe : ClearData14 working routine

-- =======================
-- Parameter check\control
-- =======================

IF @Command IS NULL OR @winlostdate IS NULL
BEGIN
	PRINT 'Invalid input parameters'
	RETURN
END

--IF -- below is ACCEPTED case
--(
--	(@Command = 'ALL_DB') -- delete on all server
--	--OR
--	--(@Command = 'Except_DBTRANS' AND @@ServerName <> 'DBTRANS') 
--)
BEGIN
	-- =================
	-- BEGIN DELETE DATA
	-- =================
	PRINT 'DELETE DATA'

	Declare @rc int, @rn int, @rn2 int

	DELETE TOP (250000)
	FROM dbo.bettrans14
	WHERE winlostdate = @winlostdate
	
	IF @@ROWCOUNT > 0 RETURN
	PRINT 'Done deleting bettrans14'

	DELETE TOP (250000)
	FROM dbo.bettrans14_Agent
	WHERE winlostdate = @winlostdate
	
	IF @@ROWCOUNT > 0 RETURN
	PRINT 'Done deleting bettrans14_Agent'


	CREATE TABLE #btm (rn int PRIMARY KEY IDENTITY(1,1), transid int)


	BEGIN
		INSERT INTO #btm (transid)
		SELECT transid
		FROM bettransm14 with (ROWLOCK)
		WHERE winlostdate = @winlostdate
	END


	SET @rn  = 1
	SET @rn2 = 50000
	SET @rc  = 1
	WHILE @rc > 0
	BEGIN
		BEGIN TRANSACTION
			DELETE B
			FROM dbo.bettransm14 B
				INNER JOIN #btm T ON B.transid = T.transid
			WHERE
				T.rn BETWEEN @rn AND @rn2

			SET @rc = @@ROWCOUNT
		COMMIT TRANSACTION

		SET @rn  = @rn  + 50000
		SET @rn2 = @rn2 + 50000
	END
	DROP TABLE #btm

	SET @rc = 1
	WHILE @RC > 0
	BEGIN
		BEGIN TRANSACTION
		DELETE TOP (5000)
		FROM Sum_WinLoss_Cust with (ROWLOCK)
		WHERE winlostdate <= @winlostdate

		SET @rc = @@ROWCOUNT
		COMMIT TRANSACTION
	END

	SET @rc = 1
	WHILE @RC > 0
	BEGIN
		BEGIN TRANSACTION
		DELETE TOP (5000)
		FROM Sum_WinLoss_Agent with (ROWLOCK)
		WHERE winlostdate <= @winlostdate

		SET @rc = @@ROWCOUNT
		COMMIT TRANSACTION
	END

	IF EXISTS (select * from dbo.sysobjects where name = 'Bettrans_Sum') 
	BEGIN
		DELETE FROM Bettrans_Sum WHERE winlostdate = @winlostdate
	END

	IF EXISTS (select * from dbo.sysobjects where name = 'Bettrans_Agent_Sum') 
	BEGIN
		DELETE FROM Bettrans_Agent_Sum WHERE winlostdate = @winlostdate
	END
	-- =====
	--  END
	-- =====
END

--ELSE
---- Below is UN-ACCEPTED CASE
--BEGIN
--	--IF @Command = 'Except_DBTRANS' AND @@ServerName = 'DBTRANS'
--	--	PRINT 'DBTRANS Exception'	
--	--ELSE
--	BEGIN
--		PRINT 'Invalid input parameters'
--		RETURN
--	END
--END

SET NOCOUNT OFF
