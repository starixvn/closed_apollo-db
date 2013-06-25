 
/****** Object:  StoredProcedure [dbo].[Task_BalanceUp_ProdDB]    Script Date: 05/21/2013 00:09:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_BalanceUp_ProdDB]
	@fdate as date 
AS
/*
Created by:  Sophia
Date:  20130603
Task: Call FROM DBTRANS, Delete Odds, LiveScore
DB: SVRPRO.PRODB
Original: IBC.Task_BalanceUp_DB02
Revisions: 
	 

*/
SET NOCOUNT ON

	DELETE FROM odds where matchid not in (SELECT matchid FROM match WITH (NOLOCK))
	DELETE FROM liveScore where matchid not in (SELECT matchid FROM match WITH (NOLOCK) union all SELECT matchid FROM match14 WITH (NOLOCK))
GO
 