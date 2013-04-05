CREATE PROCEDURE [dbo].[Age_Exchange_GetById]
    @ExchangeId			INT
AS

/*  
 * Created: 20130320@Lewis
 * Task : Select exchange rate by id
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
	WHERE [exchangeid] = @ExchangeId

END