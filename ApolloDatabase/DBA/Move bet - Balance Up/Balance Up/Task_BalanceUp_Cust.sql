USE [TransDB]
GO
/****** Object:  StoredProcedure [dbo].[Task_BalanceUp_Cust]    Script Date: 1/29/2015 12:22:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_BalanceUp_Cust]
	@winlostdate smalldatetime,
	@preview bit = 0
AS
/*
	Created by: Dan
	Date: 2013-06-04
	Task: Delete BalanceTable_Tmp to insert balance into bettrans
	DB: SVRTXN.TRANSDB
	Orginal SP: bodb02.Task_BalanceUp_SubAgent
	Revisions:
		
*/
SET NOCOUNT ON
--create table #recommend (KeyID int PRIMARY KEY IDENTITY(1,1), recommend int, ticketCount int)
create table #custid (KeyID int PRIMARY KEY IDENTITY(1,1), custid int, ticketCount int)

Declare @rKeyID int, @cKeyID int
-- Get ticketcount per cust
-- Note that data is sorted by TicketCount DESC, so that customer with less tickets will be picked first.

insert into #custid (custid, ticketCount)
select custid, SUM(ticketCount) c
FROM balanceTable_tmp
GROUP BY custid
ORDER BY c, custid --DESC

Declare @custid_list varchar(2100), @ticket_cnt int, @custid_cnt int, @rc int, @r int
Declare @keyID int, @custid_listustid int, @custid int, @ticketCount int

SET @rKeyID = 1
SET @r = 1

NewCustList:
SET @custid_list = ''
SET @ticket_cnt = 0
SET @custid_cnt = 0

AddCust:
SELECT @keyID = keyID, @custid = custid, @ticketCount = ticketCount
FROM #custid 
WHERE keyID = @rKeyID

SET @rc = @@ROWCOUNT
IF @rc > 0
BEGIN
	SET @custid_list = @custid_list + CAST(@custid as varchar(40)) + ','
	SET @ticket_cnt = @ticket_cnt + @ticketCount
	SET @custid_cnt = @custid_cnt + 1

	--DELETE FROM #recommend WHERE KeyID = @keyID
	SET @rKeyID = @rKeyID + 1
END

-- if ticket<5000 and @custid_list is still enough to add more and number of customer<200 --> add more customer to process
IF (@ticket_cnt < 5000) AND LEN(@custid_list) < 2000 AND @custid_cnt < 200 AND @rc > 0 
	GOTO AddCust -- add next cust into list until condition meet

IF @custid_cnt > 0
BEGIN
	SET @custid_list = LEFT(@custid_list, LEN(@custid_list) -1)

	IF @preview = 1
	BEGIN
		PRINT CAST(@r as varchar(40)) + '  Total Ticket : ' + CAST(@ticket_cnt as varchar(40)) + '  Total custid : ' + CAST(@custid_cnt as varchar(40)) + '   ' + @custid_list
		SET @r = @r + 1
	END
	ELSE
	BEGIN
		BEGIN TRY
		
			BEGIN TRANSACTION
			DELETE FROM dbo.balanceTable_tmp
			WHERE custid IN (select val from dbo.strSplit(@custid_list, ','))

			EXEC dbo.ExecRep_07 @custids = @custid_list,
								@isAgent = 0 ,
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

--IF IsNull(@ticketCount,0) > 10000 GOTO PickNextCust -- if ticketCount per 1 agent over 10000, go to loop for each custid
IF @rc > 0 GOTO NewCustList

