ALTER PROCEDURE [dbo].[Acc_ExchangeSelByID]
	@ExchangeID int
AS

/*
Created: 20130822@Sophia
Task : Select currency by Id
DB: SVRCSD.RepDB
Original:

Revisions:
	 
Param's Explanation:
	• @ExchangeID: specify exchange-rate of the currency

*/

SET NOCOUNT ON
BEGIN
	SELECT	Exchangeid, Currency, Actualrate, Creator, Minbet, Minbetlive, Description, MultipliedBy 
	FROM	Exchange WITH(NOLOCK)
	WHERE	Exchangeid = @ExchangeID
END

GO
GRANT  EXECUTE  ON [dbo].[Acc_ExchangeSelByID]  TO [aplweb]