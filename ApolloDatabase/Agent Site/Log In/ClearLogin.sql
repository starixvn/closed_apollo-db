USE [OnlineDB]
GO
/****** Object:  StoredProcedure [dbo].[ClearLogin]    Script Date: 12/12/2013 10:03:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ClearLogin]
AS
/*
	Task:  
	DB:OnlineDB
	Original SP: 	
	Revisions:
		- 20130927@Gary: First version.		
		- 20131211@Dan: delete OnAgent
	Param's Explanation: 
*/
BEGIN
	SET NOCOUNT ON

	DECLARE 
		@CustNumber int = 0,
		@AgentNumber int = 0,
		@AdminNumber int = 0
          
	DELETE OnCust 
	FROM OnCust WITH (ROWLOCK, UPDLOCK)
	WHERE reload_time < dateadd(minute,-10,CURRENT_TIMESTAMP)
	SET @CustNumber= @@rowcount 
	
	DELETE OnAgent
	FROM OnAgent WITH (ROWLOCK, UPDLOCK)
	WHERE ReloadTime < dateadd(minute,-15,CURRENT_TIMESTAMP)	
	SET @AgentNumber =@@rowcount	

	DELETE OnAdmin
	FROM OnAdmin WITH (ROWLOCK, UPDLOCK)
	WHERE reload_time < dateadd(minute,-10,CURRENT_TIMESTAMP)
	SET @AdminNumber = @@rowcount

	-- log message for job history
	   PRINT '### deleted ' + CAST(@CustNumber as varchar(20)) + ' OnCust records  deleted ' + CAST(@AgentNumber as varchar(20)) + ' OnAgent records  deleted ' + CAST(@AdminNumber as varchar(20)) + ' OnAdmin records ###'

END