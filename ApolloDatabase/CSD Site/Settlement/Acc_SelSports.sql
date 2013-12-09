CREATE PROCEDURE [dbo].[Acc_SelSports]
	@isGetAll BIT = 0
AS
/**
 * Created by	: Kaden
 * Date			: 20130318
 * Task			: Get the list of sports for Settlement function
 * DB			: APL.ProdDB
 * Revisions	:
 *	•
 * Parameters:
 * @isGetAll: 1 - get all sports for view result, 0- get only sportbook + number game for calculating settlement
 *  
 */

BEGIN
	SET NOCOUNT ON 
	
	SELECT * 
	FROM	Sports WITH (NOLOCK)
	WHERE	sporttype NOT IN(
				201, --Financial 				
				251,252,253,  --Casino, Bingo, Game 
				162, --live casino		
				161 --number games
			) 
			AND
			(@isGetAll=1 or sporttype NOT IN(				
				151,152,153,  --Racing								
				180, 181, 182, 183, 184, 185, 186 --virtual sports
			))
END	
GRANT EXECUTE ON [dbo].[Acc_SelSports] TO [aplweb]	