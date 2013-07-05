CREATE PROCEDURE [dbo].[Task_AutoSettlement_Loop]
AS
/*
	Created by:Dan
	Date:20130702
	Task: execute auto settlement (job)
	DB: SVRTXN/TRANSDB
	
	Revisions:
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @start DATETIME
	SELECT @start = CURRENT_TIMESTAMP

	WHILE (1=1) AND (DATEDIFF(minute,@start, CURRENT_TIMESTAMP) < 30)
	BEGIN
		EXEC [Task_AutoSettlement]
		WAITFOR DELAY '00:00:01'
	END
END