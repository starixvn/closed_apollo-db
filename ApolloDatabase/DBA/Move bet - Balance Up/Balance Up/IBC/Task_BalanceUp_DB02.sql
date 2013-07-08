USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_BalanceUp_DB02]    Script Date: 05/21/2013 00:09:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_BalanceUp_DB02]
	@fdate as datetime
AS
/*
Created by:  
Date:  
Task: Call from DBTRANS
DB: DB02.bodb02
Revisions:
	-- 20130603@Sophia: Put Delete code into ExecRep_APL_03

*/
SET NOCOUNT ON

	EXEC ExecRep_APL_03 @fdate

Go
 