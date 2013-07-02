ALTER PROCEDURE [dbo].[Age_BetList_SelWinloss]
	@LoggedId INT,
	@AgentId INT = -1 ,
	@CustId INT = -1,
	@FromDate DATE, 
	@Todate DATE,
	@StatusIds VARCHAR(1000),
	@MoveBetsDay SMALLDATETIME,
	@Sporttypes VARCHAR(1000) = '0',
	@Bettypes VARCHAR(1000) = '0'

 AS
/*
Created: 20130301@Sophia
Task : Betlist for Winloss report
DB:  SVRAGE.RepDB
Original:  

Revisions:
     - 20130510@Sophia: Change @splitter of strSplit_Key from '^', to ','
	 - 20130628@Sophia: Add FinalHomeScore, FinalAwayScore
	 - 20130701@Sophia: Modify for Singbet: filter by Sporttype and Bettype

Param's Explanation:  
				
*/  
SET NOCOUNT ON

	---*****************************  Super View ***************************--
	IF @LoggedId = 0 
	BEGIN 
		----1: Super View Super
		IF @AgentId = 0 AND @CustID = -1
		BEGIN 		
			EXEC Age_BetList_SelWinloss_SuperViewSuper  @LoggedId = 0, @AgentId = 0 ,@CustId = -1, 
														@FromDate = @FromDate, @Todate = @Todate,@StatusIds = @StatusIds ,
														@MoveBetsDay = @MoveBetsDay ,@Sporttypes = @Sporttypes ,@Bettypes = @Bettypes				
			RETURN
		END			
		ELSE
		---- 2: Super view Agent
		IF @AgentId <> -1 AND @CustID = -1
		BEGIN			
			EXEC Age_BetList_SelWinloss_SuperViewAgent  @LoggedId = 0, @AgentId = @AgentId ,@CustId = -1, 
														@FromDate = @FromDate, @Todate = @Todate ,@StatusIds = @StatusIds ,
														@MoveBetsDay = @MoveBetsDay ,@Sporttypes = @Sporttypes ,@Bettypes = @Bettypes	
			RETURN
		END
		ELSE
		---- 3: Super View Member
		IF @CustID <> -1 AND @AgentId = -1
		BEGIN 	
			EXEC Age_BetList_SelWinloss_SuperViewCust @LoggedId = 0, @AgentId = -1 ,@CustId = @CustID, 
														@FromDate = @FromDate, @Todate = @Todate ,@StatusIds = @StatusIds ,
														@MoveBetsDay = @MoveBetsDay ,@Sporttypes = @Sporttypes ,@Bettypes = @Bettypes
			RETURN
		END
	END 
	ELSE 
	--****************** 2: Agent View******************---
	BEGIN 
		----4: Agent view Agent
		IF @AgentId <> -1 AND @CustID = -1
		BEGIN 			
			EXEC Age_BetList_SelWinloss_AgentViewAgent  @LoggedId = @LoggedId, @AgentId = @AgentId ,@CustId = -1,
														@FromDate = @FromDate, @Todate = @Todate ,@StatusIds = @StatusIds ,
														@MoveBetsDay = @MoveBetsDay ,@Sporttypes = @Sporttypes ,@Bettypes = @Bettypes
		
			RETURN
		END
		ELSE
		----- 5: Agent view Member
		IF @CustID <> -1 AND @AgentId = -1
		BEGIN 
			EXEC Age_BetList_SelWinloss_AgentViewCust @LoggedId = @LoggedId, @AgentId = -1 ,@CustId = @CustId,
														@FromDate = @FromDate, @Todate = @Todate ,@StatusIds = @StatusIds ,
														@MoveBetsDay = @MoveBetsDay ,@Sporttypes = @Sporttypes ,@Bettypes = @Bettypes
			RETURN
		END 
	END

GO
GRANT EXECUTE ON [dbo].[Age_BetList_SelWinloss] TO [aplweb]
GO 