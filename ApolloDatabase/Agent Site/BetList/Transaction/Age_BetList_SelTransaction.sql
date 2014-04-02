ALTER PROCEDURE [dbo].[Age_BetList_SelTransaction_Xtest1]
	@LoggedId INT,
	@AgentId INT = -1 ,
	@CustId INT = -1,
	@FromDate SMALLDATETIME, 
	@Todate SMALLDATETIME,
	@Sporttypes VARCHAR(1000) ='0',
	@Bettypes VARCHAR(1000) = '0'

 AS
/*
Created: 20130301@Sophia
Task : Betlist for Transaction report
DB:  SVRAGE.RepDB
Original:  [Age_BetList_SelTransaction]

Revisions:  
 
Param's Explanation:  
	+ @IsAgent = 1 : by Agent's Username,
			   = 0 : by Member's Username
			
Note: select top 200 at bettrans , bettrans14 				
*/  
 
SET NOCOUNT ON



---*****************************  Super View ***************************--
IF @LoggedId = 1
BEGIN 
	IF @AgentId = 1 AND @CustID = -1
	----- 1: Super View by Super	
	BEGIN 		
		EXEC Age_BetList_SelTransaction_SuperViewSuper 
			@LoggedId = 1 ,  
			@FromDate = @FromDate, @Todate = @Todate,  
			@Sporttypes = @Sporttypes, @Bettypes = @Bettypes 
		RETURN				
	END
	ELSE
	IF @AgentId <> -1 AND @CustID = -1
	------ 2: Super view by Agent		
	BEGIN
		EXEC Age_BetList_SelTransaction_SuperViewAgent
			@LoggedId = 1, @AgentId = @AgentId ,
			@FromDate = @FromDate, @Todate = @Todate,  
			@Sporttypes = @Sporttypes, @Bettypes = @Bettypes
		RETURN
	END
	ELSE

	IF @CustID <> -1 AND @AgentId = -1
	BEGIN 
	---- 3: Super View By Member
		EXEC Age_BetList_SelTransaction_SuperViewCust
				@LoggedId = 1, @CustId = @CustId,
				@FromDate = @FromDate, @Todate = @Todate, 
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
		EXEC Age_BetList_SelTransaction_AgentViewAgent
				@LoggedId = @LoggedId, @AgentId = @AgentId , 
				@FromDate = @FromDate, @Todate = @Todate, 
				@Sporttypes = @Sporttypes, @Bettypes = @Bettypes 
		RETURN
	END
	ELSE
	----- 5: Agent view By Member
	IF @CustID <> -1 AND @AgentId = -1
	BEGIN 
		EXEC Age_BetList_SelTransaction_AgentViewCust
				@LoggedId = @LoggedId,  @CustId = @CustId,
				@FromDate = @FromDate, @Todate = @Todate,  
				@Sporttypes = @Sporttypes, @Bettypes = @Bettypes 
		RETURN

	END 
END



GO
GRANT EXECUTE ON [dbo].[Age_BetList_SelTransaction] TO [aplweb]
GO 
