 
/****** Object:  StoredProcedure [dbo].[Task_Archive_ParlayResult]    Script Date: 05/22/2013 23:59:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_ParlayResult]
AS
/*
Created: Sophia
Date:  20130530
Task : Archive data to SVRARC.ArchiveDB.dbo.betParlayResult_BK  
DB: SVRTXN.TransDB
Original: IBC.Task_Archive_ParlayResult

Revisions:
 
	
Param's Explanation: 

*/	
SET NOCOUNT ON
	Declare @winlostdate smalldatetime
	
	SELECT @winlostdate = MAX(winlostdate)
	FROM dbo.Task_ArchiveDate

	INSERT INTO SVRARC.ArchiveDB.dbo.betParlayResult
		(rID,RefNo,Serial,transid,winlostdate,statusid,stake,Odds,mOdds,winlost,playercomm)
	SELECT rID,RefNo,Serial,transid,winlostdate,statusid,stake,Odds,mOdds,winlost,playercomm
	FROM  dbo.betParlayResult
	WHERE winlostdate <= @winlostdate

	INSERT INTO SVRARC.ArchiveDB.dbo.betParlayResult_Agent
		(rID,AgentId,RefNo,Serial,transid,winlostdate,statusid,stake,awinlost,acomm)
	SELECT rID,AgentId,RefNo,Serial,transid,winlostdate,statusid,stake,awinlost,acomm
	FROM  dbo.BetParlayResult_Agent
	WHERE winlostdate <= @winlostdate