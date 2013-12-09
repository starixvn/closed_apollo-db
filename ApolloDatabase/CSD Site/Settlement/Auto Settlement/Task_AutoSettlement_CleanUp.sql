/****** Object:  Stored Procedure dbo.Task_ExternalSettlement_CleanUp    Script Date: 11/22/2012 1:48:30 PM ******/
CREATE PROCEDURE [dbo].[Task_AutoSettlement_CleanUp]
	@winlostdate date
AS
/*
	Created by: Dan
	Date:2013/07/02
	Task: clean command (by move bet date)
	DB: SVRTRANS/TRANSDB
	
	Revisions:
		
	Param explanation:
		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @movedDate	DATETIME,
			@LogDate	DATETIME,	
			@errmsg		VARCHAR(200)

	SELECT	@LogDate = GETDATE()

	INSERT INTO SVRLOG.[LogDB].[dbo].[AutoSettlementCommand_History]
		 ([StatusID]
           ,[SPName]
           ,[SQLCommand]
           ,[ActionId]
           ,[CreatedDate]
           ,[ExecutedDate]
           ,[RetryCount]
           ,[MatchID]
           ,[Status]
           ,[Duration]           
           ,[AllowedDate])
		SELECT  [StatusID]
           ,[SPName]
           ,[SQLCommand]
           ,[ActionId]
           ,[CreatedDate]
           ,[ExecutedDate]
           ,[RetryCount]
           ,[MatchID]
           ,[Status]
           ,[Duration]           
           ,[AllowedDate]
		FROM [dbo].AutoSettlementCommand a WITH (NOLOCK)			
		WHERE MatchID in (Select matchID From Match WITH (NOLOCK) Where eventdate=@winlostdate
					UNION ALL 
					Select orid From outright WITH (NOLOCK) Where eventdate=@winlostdate
		)			
		
	IF @@ERROR <> 0
	BEGIN
		SET @errmsg  = 'Cannot move auto settlement command (moved date: ' + CONVERT(VARCHAR(20),@winlostdate) + ')'
		RAISERROR(@errmsg,16,1)		
	END
		
	DELETE FROM [dbo].AutoSettlementCommand WITH(ROWLOCK)
	WHERE 
		MatchID in (
				Select matchID From Match WITH (NOLOCK) Where eventdate=@winlostdate
			UNION ALL 
				Select orid From outright WITH (NOLOCK) Where eventdate=@winlostdate
			)			

	IF @@ERROR <> 0
	BEGIN
		SET @errmsg  = 'Cannot delete data after moving settlement command to log (moved date: ' + CONVERT(VARCHAR(20),@winlostdate) + ')'
		RAISERROR(@errmsg,16,1)
	END
END