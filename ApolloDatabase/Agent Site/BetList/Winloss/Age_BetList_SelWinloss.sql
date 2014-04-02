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
	 - 20130708@Sophia: Change SuperId from 0 to 1 (@AgentID = 1)
	 - 20130730@Sophia: Revise code

Param's Explanation:  
				
*/  
SET NOCOUNT ON

	---*****************************  Super View ***************************--
	IF @LoggedId = 1 
	BEGIN 	
		EXEC Age_BetList_SelWinloss_SuperViewCust   @LoggedId = 1, @CustId = @CustID, 
													@FromDate = @FromDate, @Todate = @Todate,
													@MoveBetsDay = @MoveBetsDay ,@Sporttypes = @Sporttypes ,@Bettypes = @Bettypes		
	END 
	ELSE 
	--****************** 2: Agent View******************---
	BEGIN 
		EXEC Age_BetList_SelWinloss_AgentViewCust   @LoggedId = @LoggedId, @CustId = @CustId,
													@FromDate = @FromDate, @Todate = @Todate, 
													@MoveBetsDay = @MoveBetsDay ,@Sporttypes = @Sporttypes ,@Bettypes = @Bettypes
			
		 
	END

GO
GRANT EXECUTE ON [dbo].[Age_BetList_SelWinloss] TO [aplweb]
GO 