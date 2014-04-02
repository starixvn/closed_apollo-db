ALTER PROCEDURE [dbo].[Age_BetList_SelByDateMemStatus_Old]
	@LoggedId INT,
	@AgentId INT = -1 ,
	@CustId INT = -1,
	@FromDate SMALLDATETIME, 
	@Todate SMALLDATETIME,
	@StatusIds VARCHAR(1000),
	@Sporttypes VARCHAR(1000) ='0',
	@Bettypes VARCHAR(1000) = '0',
	@RptType SMALLINT = 0
	

 AS
/*
Created: 20131009@Sophia
Task : Betlist for Outstanding report/ Cancel Bets Report/ Account Info-Betlist
DB:  SVRARC.ArchiveDB
Original:  

Revisions:
   

Param's Explanation:  
	@RptType:
			----  = 0: Called from Account Info-Betlist
			----  = 1: Called from Transaction report
			----  = 2: Called from Outstanding Report
			  = 3: Called from ticket cancel report
	
*/  
SET NOCOUNT ON



---*****************************  Super View ***************************--
IF @LoggedId = 1 
BEGIN 
	IF @AgentId = 1 AND @CustID = -1
	----- 1: Super View by Super	
	BEGIN 		
		EXEC Age_BetList_SelByDateMemStatus_SuperViewSuper_Old 
			@LoggedId = 1, @AgentId = 1 ,@CustId = -1,
			@FromDate = @FromDate, @Todate = @Todate, @StatusIds = @StatusIds,
			@Sporttypes = @Sporttypes, @Bettypes = @Bettypes, @RptType = @RptType
		RETURN				
	END
	ELSE
	IF @AgentId <> -1 AND @CustID = -1
	------ 2: Super view by Agent		
	BEGIN
		EXEC Age_BetList_SelByDateMemStatus_SuperViewAgent_Old
			@LoggedId = 1, @AgentId = @AgentId ,@CustId = -1,
			@FromDate = @FromDate, @Todate = @Todate, @StatusIds = @StatusIds,
			@Sporttypes = @Sporttypes, @Bettypes = @Bettypes, @RptType = @RptType
		RETURN
	END
	ELSE

	IF @CustID <> -1 AND @AgentId = -1
	BEGIN 
	---- 3: Super View By Member
		EXEC Age_BetList_SelByDateMemStatus_SuperViewCust_Old
				@LoggedId = 1, @AgentId = -1 ,@CustId = @CustId,
				@FromDate = @FromDate, @Todate = @Todate, @StatusIds = @StatusIds,
				@Sporttypes = @Sporttypes, @Bettypes = @Bettypes, @RptType = @RptType	
		RETURN				
	END
END 
ELSE 
--****************** 2: Agent View******************---
BEGIN 
	----4: Agent view By Agent
	IF @AgentId <> -1 AND @CustID = -1
	BEGIN 
		EXEC Age_BetList_SelByDateMemStatus_AgentViewAgent_Old
				@LoggedId = @LoggedId, @AgentId = @AgentId ,@CustId = -1,
				@FromDate = @FromDate, @Todate = @Todate, @StatusIds = @StatusIds,
				@Sporttypes = @Sporttypes, @Bettypes = @Bettypes, @RptType = @RptType
		RETURN
	END
	ELSE
	----- 5: Agent view By Member
	IF @CustID <> -1 AND @AgentId = -1
	BEGIN 
		EXEC Age_BetList_SelByDateMemStatus_AgentViewCust_Old 
				@LoggedId = @LoggedId, @AgentId = -1 ,@CustId = @CustId,
				@FromDate = @FromDate, @Todate = @Todate, @StatusIds = @StatusIds,
				@Sporttypes = @Sporttypes, @Bettypes = @Bettypes, @RptType = @RptType
		RETURN

	END 
END


GO
GRANT EXECUTE ON [dbo].[Age_BetList_SelByDateMemStatus_Old] TO [aplweb]
GO 