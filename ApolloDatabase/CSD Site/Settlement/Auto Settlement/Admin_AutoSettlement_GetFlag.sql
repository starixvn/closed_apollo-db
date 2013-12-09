ALTER PROCEDURE  [dbo].[Admin_AutoSettlement_GetFlag]			
AS
/*
	Created by:Dan
	Date:20130702
	Task: get settlement flag in system
	DB: SVRTRANS/TRANSDB	
	Revisions:		

	Param explanation:								
			
*/
BEGIN
SET NOCOUNT ON

SELECT CAST([VValue] as BIT) isUsingAutoSettlement	
FROM SystemSettings	
WHERE VName='isUsingAutoSettlement'

END 

GO 
GRANT EXECUTE ON [dbo].[Admin_AutoSettlement_GetFlag] TO [aplweb]	