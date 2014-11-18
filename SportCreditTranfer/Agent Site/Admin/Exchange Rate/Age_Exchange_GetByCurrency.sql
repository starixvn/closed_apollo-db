CREATE PROCEDURE [dbo].[Age_Exchange_GetByCurrency]
    @Currency NVARCHAR(50)
AS

/*  
 * Created: 20130320@Lewis
 * Task : Select exchange rate by currency
 * DB: [REPDB]
 *  
 * Revisions:
 * Param's Explanation:
*/

BEGIN

	SELECT [exchangeid]
		  ,[currency]
		  ,[actualrate]
		  ,[minbet]
		  ,[minbetlive]
		  ,[Description]
		  ,[MultipliedBy]
	FROM [dbo].[Exchange]
	WHERE [Currency] = @Currency

END