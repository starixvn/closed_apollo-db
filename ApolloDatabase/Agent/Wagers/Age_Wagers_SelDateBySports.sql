ALTER PROCEDURE [dbo].[Age_Wagers_SelDateBySports]
@Sporttypes VARCHAR(MAX) = '0'
AS
/*
Created:  Sophia
Date: 20130701
Task: Get date for Wagers EM
DB: SVRAGE.REPDB
 
Revisions:    

Parameters:
 
*/

SET NOCOUNT ON

DECLARE @Date DATE
SELECT @Date = GETDATE()


SELECT DISTINCT m.eventdate 
FROM		match m WITH (NOLOCK) 
INNER JOIN	bettrans b WITH (NOLOCK) 
		ON	m.matchid = b.matchid
WHERE	m.eventdate > @Date
		AND m.sporttype IN (SELECT val FROM strSplit_Key (@Sporttypes,','))

GO 
GRANT EXECUTE ON [Age_Wagers_SelDateBySports] To [aplweb]

 