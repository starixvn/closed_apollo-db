ALTER  PROCEDURE [dbo].[Age_BetList_SelTransaction]
	@LoggedId INT,
	@AgentId INT = -1 ,
	@CustId INT = -1,
	@FromDate SMALLDATETIME, 
	@Todate SMALLDATETIME,
	@StatusIds VARCHAR(1000),
	@MoveBetsDay SMALLDATETIME, 
	@Sporttypes VARCHAR(1000) ='0',
	@Bettypes VARCHAR(1000) = '0'

 AS
/*
Created: 20130301@Sophia
Task : Betlist for Transaction report
DB:  SVRAGE.RepDB
Original:  [Age_BetList_SelByDateMemStatus]

Revisions:  
   - 20130510@Sophia: Change @splitter of strSplit_Key from '^', to ','
   - 20130628@Sophia: Add FinalHomeScore, FinalAwayScore

Param's Explanation:  
	+ @IsAgent = 1 : by Agent's Username,
			   = 0 : by Member's Username
				
*/  
 
SET NOCOUNT ON



---*****************************  Super View ***************************--
IF @LoggedId = 0 
BEGIN 
	IF @AgentId = 0 AND @CustID = -1
	----- 1: Super View by Super	
	BEGIN 		
		EXEC Age_BetList_SelByDateMemStatus_SuperViewSuper 
			@LoggedId = 0, @AgentId = 0 ,@CustId = -1,
			@FromDate = @FromDate, @Todate = @Todate, @StatusIds = @StatusIds,
			@Sporttypes = @Sporttypes, @Bettypes = @Bettypes, @RptType = 1, @MoveBetsDay = @MoveBetsDay
		RETURN				
	END
	ELSE
	IF @AgentId <> -1 AND @CustID = -1
	------ 2: Super view by Agent		
	BEGIN
		EXEC Age_BetList_SelByDateMemStatus_SuperViewAgent
			@LoggedId = 0, @AgentId = @AgentId ,@CustId = -1,
			@FromDate = @FromDate, @Todate = @Todate, @StatusIds = @StatusIds,
			@Sporttypes = @Sporttypes, @Bettypes = @Bettypes, @RptType = 1, @MoveBetsDay = @MoveBetsDay
		RETURN
	END
	ELSE

	IF @CustID <> -1 AND @AgentId = -1
	BEGIN 
	---- 3: Super View By Member
		EXEC Age_BetList_SelByDateMemStatus_SuperViewCust
				@LoggedId = 0, @AgentId = -1 ,@CustId = @CustId,
				@FromDate = @FromDate, @Todate = @Todate, @StatusIds = @StatusIds,
				@Sporttypes = @Sporttypes, @Bettypes = @Bettypes, @RptType = 1, @MoveBetsDay = @MoveBetsDay	
		RETURN				
	END
END 
ELSE 
--****************** 2: Agent View******************---
BEGIN 
	----4: Agent view By Agent
	IF @AgentId <> -1 AND @CustID = -1
	BEGIN 
		EXEC Age_BetList_SelByDateMemStatus_AgentViewAgent
				@LoggedId = @LoggedId, @AgentId = @AgentId ,@CustId = -1,
				@FromDate = @FromDate, @Todate = @Todate, @StatusIds = @StatusIds,
				@Sporttypes = @Sporttypes, @Bettypes = @Bettypes, @RptType = 1, @MoveBetsDay = @MoveBetsDay
		RETURN
	END
	ELSE
	----- 5: Agent view By Member
	IF @CustID <> -1 AND @AgentId = -1
	BEGIN 
		EXEC Age_BetList_SelByDateMemStatus_AgentViewCust
				@LoggedId = @LoggedId, @AgentId = -1 ,@CustId = @CustId,
				@FromDate = @FromDate, @Todate = @Todate, @StatusIds = @StatusIds,
				@Sporttypes = @Sporttypes, @Bettypes = @Bettypes, @RptType = 1, @MoveBetsDay = @MoveBetsDay
		RETURN

	END 
END



GO
GRANT EXECUTE ON [dbo].[Age_BetList_SelTransaction] TO [aplweb]
GO 
