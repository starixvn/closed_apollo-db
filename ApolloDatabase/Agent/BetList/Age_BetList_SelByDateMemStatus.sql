ALTER  PROCEDURE [dbo].[Age_BetList_SelByDateMemStatus]
	@LoggedId INT,
	@AgentId INT = -1 ,
	@CustId INT = -1,
	@FromDate SMALLDATETIME, 
	@Todate SMALLDATETIME,
	@StatusIds VARCHAR(1000),
	@Sporttypes VARCHAR(1000) ='0',
	@Bettypes VARCHAR(1000) = '0'

 AS
/*
Created: 20130301@Sophia
Task : Betlist for Outstanding report/ Cancel Bets Report/ Account Info-Betlist
DB:  SVRAGE.RepDB
Original:  

Revisions:
   - 20130510@Sophia: Change @splitter of strSplit_Key from '^', to ','
   - 20130628@Sophia: Add FinalHomeScore, FinalAwayScore, UGroup for Singbet
   - 20130708@Sophia: Change SuperId from 0 to 1 (@AgentID = 1)


Param's Explanation:  
	
*/  
SET NOCOUNT ON



---*****************************  Super View ***************************--
IF @LoggedId = 1 
BEGIN 
	IF @AgentId = 1 AND @CustID = -1
	----- 1: Super View by Super	
	BEGIN 		
		EXEC Age_BetList_SelByDateMemStatus_SuperViewSuper 
			@LoggedId = 1, @AgentId = 1 ,@CustId = -1,
			@FromDate = @FromDate, @Todate = @Todate, @StatusIds = @StatusIds,
			@Sporttypes = @Sporttypes, @Bettypes = @Bettypes
		RETURN				
	END
	ELSE
	IF @AgentId <> -1 AND @CustID = -1
	------ 2: Super view by Agent		
	BEGIN
		EXEC Age_BetList_SelByDateMemStatus_SuperViewAgent
			@LoggedId = 1, @AgentId = @AgentId ,@CustId = -1,
			@FromDate = @FromDate, @Todate = @Todate, @StatusIds = @StatusIds,
			@Sporttypes = @Sporttypes, @Bettypes = @Bettypes
		RETURN
	END
	ELSE

	IF @CustID <> -1 AND @AgentId = -1
	BEGIN 
	---- 3: Super View By Member
		EXEC Age_BetList_SelByDateMemStatus_SuperViewCust 
				@LoggedId = 1, @AgentId = -1 ,@CustId = @CustId,
				@FromDate = @FromDate, @Todate = @Todate, @StatusIds = @StatusIds,
				@Sporttypes = @Sporttypes, @Bettypes = @Bettypes	
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
				@Sporttypes = @Sporttypes, @Bettypes = @Bettypes
		RETURN
	END
	ELSE
	----- 5: Agent view By Member
	IF @CustID <> -1 AND @AgentId = -1
	BEGIN 
		EXEC Age_BetList_SelByDateMemStatus_AgentViewCust 
				@LoggedId = @LoggedId, @AgentId = -1 ,@CustId = @CustId,
				@FromDate = @FromDate, @Todate = @Todate, @StatusIds = @StatusIds,
				@Sporttypes = @Sporttypes, @Bettypes = @Bettypes
		RETURN

	END 
END


GO
GRANT EXECUTE ON [dbo].[Age_BetList_SelByDateMemStatus] TO [aplweb]
GO 