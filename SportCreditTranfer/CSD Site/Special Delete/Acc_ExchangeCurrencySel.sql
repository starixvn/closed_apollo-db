CREATE PROCEDURE [dbo].[Acc_ExchangeCurrencySel]
AS
/*
	Created by: Sophia
	Date:  20130311
	Task:  
	DB: SVRCSD.RepDB	
	Original: 
	
	Revisions:
			
	Param's Explanation:	

		
*/		
SET NOCOUNT ON

	SELECT exchangeid, currency FROM exchange WITH (NOLOCK)

GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeCurrencySel] TO [aplWeb] 
GO
--GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeCurrencySel] TO [vnteam]