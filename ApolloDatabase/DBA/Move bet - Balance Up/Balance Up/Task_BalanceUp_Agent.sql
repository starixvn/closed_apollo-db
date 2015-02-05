USE [TransDB]
GO
/****** Object:  StoredProcedure [dbo].[Task_BalanceUp_Agent]    Script Date: 1/29/2015 12:23:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_BalanceUp_Agent]
	@winlostdate smalldatetime,
	@preview bit = 0
AS

/*
	Created by: Dan
	Date: 2013-06-04
	Task: Delete BalanceTable_Agent_Tmp to insert balance into bettrans_Agent
	DB: SVRTXN.TRANSDB
	Orginal SP: bodb02.Task_BalanceUp_SubAgent
	Revisions:
		
*/
SET NOCOUNT ON
--create table #recommend (KeyID int PRIMARY KEY IDENTITY(1,1), recommend int, ticketCount int)
create table #agent (KeyID int PRIMARY KEY IDENTITY(1,1), agentid int, ticketCount int)

Declare @rKeyID int, @cKeyID int
-- Get ticketcount per agent
-- Note that data is sorted by TicketCount DESC, so that agent with less tickets will be picked first.

insert into #agent (agentid, ticketCount)
select agentid, SUM(ticketCount) c
FROM BalanceTable_Agent_Tmp 
GROUP BY agentid
ORDER BY c, agentid --DESC

Declare @agentid_list varchar(2100), @ticket_cnt int, @agentid_cnt int, @rc int, @r int
Declare @keyID int, @agentid_listustid int, @agentid int, @ticketCount int

SET @rKeyID = 1
SET @r = 1

NewAgentList:
SET @agentid_list = ''
SET @ticket_cnt = 0
SET @agentid_cnt = 0

AddAgent:
SELECT @keyID = keyID, @agentid = agentid, @ticketCount = ticketCount
FROM #agent 
WHERE keyID = @rKeyID

SET @rc = @@ROWCOUNT
IF @rc > 0
BEGIN
	SET @agentid_list = @agentid_list + CAST(@agentid as varchar(40)) + ','
	SET @ticket_cnt = @ticket_cnt + @ticketCount
	SET @agentid_cnt = @agentid_cnt + 1

	--DELETE FROM #recommend WHERE KeyID = @keyID
	SET @rKeyID = @rKeyID + 1
END

-- if ticket<5000 and @agentid_list is still enough to add more and number of customer<200 --> add more customer to process
IF (@ticket_cnt < 5000) AND LEN(@agentid_list) < 2000 AND @agentid_cnt < 200 AND @rc > 0 
	GOTO AddAgent -- add next cust into list until condition meet

IF @agentid_cnt > 0
BEGIN
	SET @agentid_list = LEFT(@agentid_list, LEN(@agentid_list) -1)

	IF @preview = 1
	BEGIN
		PRINT CAST(@r as varchar(40)) + '  Total Ticket : ' + CAST(@ticket_cnt as varchar(40)) + '  Total agentid : ' + CAST(@agentid_cnt as varchar(40)) + '   ' + @agentid_list
		SET @r = @r + 1
	END
	ELSE
	BEGIN
		BEGIN TRY
		
			BEGIN TRANSACTION
			DELETE FROM dbo.BalanceTable_Agent_Tmp
			WHERE agentid IN (select val from dbo.strSplit(@agentid_list, ','))
			
			EXEC dbo.ExecRep_07 @custids = @agentid_list,
								@isAgent = 1 ,
								@IsCreditTrans = 0,
								@winlostdate = @winlostdate

			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
			DECLARE @ErrorMessage NVARCHAR(4000);
			DECLARE @ErrorSeverity INT;
			DECLARE @ErrorState INT;

			SELECT 
				@ErrorMessage = ERROR_MESSAGE(),
				@ErrorSeverity = ERROR_SEVERITY(),
				@ErrorState = ERROR_STATE();
		
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION --RollBack in case of Error

			RAISERROR (@ErrorMessage,  @ErrorSeverity,  @ErrorState )

		END CATCH

		WAITFOR DELAY '000:00:01.200'
	END
END

--IF IsNull(@ticketCount,0) > 10000 GOTO PickNextCust -- if ticketCount per 1 agent over 10000, go to loop for each agentid
IF @rc > 0 GOTO NewAgentList

