USE [TransDB]
GO
/****** Object:  StoredProcedure [dbo].[Task_BalanceUp_Agent]    Script Date: 6/6/2013 4:31:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_BalanceUp_CreditTrans]
	@winlostdate smalldatetime,
	@preview bit = 0
AS
/*
	Created by: Sophia
	Date: 20141118
	Task: Delete BalanceCreditTrans to insert balance into CreditTrans
	DB: SVRTXN/TRANSDB
	Orginal SP: Task_BalanceUp_Agent
	Revisions:
		
*/
BEGIN 
SET NOCOUNT ON 
CREATE TABLE #AgentId (KeyID INT PRIMARY KEY IDENTITY(1,1), AgentId INT, TicketCount INT)

DECLARE @rKeyID INT, @cKeyID INT
-- Get TicketCount per Agent

-- Note that data is sorted by TicketCount ASC, so that agent with less tickets will be picked first.
INSERT INTO #AgentId (AgentId, TicketCount)
SELECT	AgentId, SUM(TicketCount) cnt
FROM	dbo.BalanceCreditTrans WITH (NOLOCK)
GROUP BY AgentId
ORDER BY cnt ASC, AgentId


Declare @AgentId_list varchar(2100), @ticket_cnt int, @AgentId_cnt int, @rc int, @r int
Declare @keyID int, @AgentId int, @TicketCount int

SET @rKeyID = 1
SET @r = 1

NewAgentList:
SET @AgentId_list = ''
SET @ticket_cnt = 0
SET @AgentId_cnt = 0

AddAgent:
SELECT @keyID = keyID, @AgentId = AgentId, @TicketCount = TicketCount
FROM #AgentId 
WHERE keyID = @rKeyID

SET @rc = @@ROWCOUNT
IF @rc > 0
BEGIN
	SET @AgentId_list = @AgentId_list + CAST(@AgentId as varchar(40)) + ','
	SET @ticket_cnt = @ticket_cnt + @TicketCount
	SET @AgentId_cnt = @AgentId_cnt + 1


	SET @rKeyID = @rKeyID + 1
END

-- if ticket<5000 and @AgentId_list is still enough to add more and number of Agentomer<200 --> add more Agentomer to process
IF (@ticket_cnt < 5000) AND LEN(@AgentId_list) < 2000 AND @AgentId_cnt < 200 AND @rc > 0 
	GOTO AddAgent -- add next Agent into list until condition meet

IF @AgentId_cnt > 0
BEGIN
	SET @AgentId_list = LEFT(@AgentId_list, LEN(@AgentId_list) -1)

	IF @preview = 1
	BEGIN
		PRINT CAST(@r as varchar(40)) + '  Total Ticket : ' + CAST(@ticket_cnt as varchar(40)) + '  Total AgentId : ' + CAST(@AgentId_cnt as varchar(40)) + '   ' + @AgentId_list
		SET @r = @r + 1
	END
	ELSE
	BEGIN
		BEGIN TRY
		
			BEGIN TRANSACTION

			DELETE FROM dbo.BalanceCreditTrans
			WHERE AgentId IN (select val from dbo.strSplit(@AgentId_list, ','))				  

			EXEC dbo.ExecRep_07 @AgentId_list, 0, 1,  @winlostdate

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

IF @rc > 0 GOTO NewAgentList

END
GO