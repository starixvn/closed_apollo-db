ALTER PROCEDURE [dbo].[Acc_ExchangeSelAccount]
AS

/*	Created by: 20130821@Sophia
	Task: Get all currencies
	DB: SVRCSD.RepDB
	Revisions:	
		 
	Param's Explanation:
*/
SET NOCOUNT ON

SELECT	Exchangeid, Currency, actualrate, commaxpayout, creator, minbet, minbetlive, Description, MultipliedBy
FROM	Exchange WITH (NOLOCK)
ORDER BY Currency

GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeSelAccount] TO [aplweb]
GO