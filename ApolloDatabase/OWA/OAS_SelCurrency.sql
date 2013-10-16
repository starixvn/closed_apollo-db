ALTER PROCEDURE  [dbo].[OAS_SelCurrency]		
	 
AS	
/*
Created: 20131016@Sophia
Task : Get all the currency for OWA
DB: SVRReport.RepDB


Revisions:
   
Param's Explanation:
*/

SET NOCOUNT ON
BEGIN

SELECT	Exchangeid, Currency
FROM	Exchange WITH (NOLOCK)
WHERE	Exchangeid NOT IN (20)
ORDER BY Currency

END
GO
 
GRANT EXECUTE ON [dbo].[OAS_SelCurrency] TO [aplweb]
GO   
  





