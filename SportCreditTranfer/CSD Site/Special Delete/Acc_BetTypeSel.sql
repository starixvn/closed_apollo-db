ALTER PROCEDURE [dbo].[Acc_BetTypeSel]
	@Mode SMALLINT = 0 
AS
/*
Created: Sophia
Date: 20130228
Task : Select bettypes for special delete
DB:  SVRCSD.RepDB
Original:

Revisions:    
    -20130719@Sophia: Add @Mode = 4 for early KO
	-20140910@Sophia: Exclude 25 bettype not offered (hardcode AND TypeId < 128 in a sort time)
Param's Explanation:
@Mode: 
	0: Special Delete
	1: Number game
	2: Mix Parlay 
	3: TicketListing
	4: Early KO
	

*/		
SET NOCOUNT ON
--type column: 0:Sport Book, 1:Number Game
CREATE TABLE #TmpBettype (typeid INT , bettypename NVARCHAR(100), type INT, liveindicator BIT)

------ sportbook
IF @Mode = 0
BEGIN
	
	INSERT INTO #TmpBettype (typeid, bettypename, type, liveindicator)
	SELECT	typeid , typenamee as bettypename, 0 as type, CASE WHEN typeid IN (1,2,3,5,7,8,12,13,15,24,25,26,27,28,124,125) THEN 1 ELSE 0 END AS liveindicator
	FROM	bettype WITH (NOLOCK)
	WHERE	typeid IN (1,2,3,4,5,6,7,8,12,13,14,15,16,20,21,24,25,26,27,28,30) 
			OR (typeid between 121 and 999 AND TypeId < 128)
END


IF @Mode = 3
BEGIN

	INSERT INTO #TmpBettype (typeid, bettypename, type, liveindicator)
	SELECT	typeid , typenamee as bettypename, 0 as type, CASE WHEN typeid IN (1,2,3,5,7,8,12,13,15,24,25,26,27,28,124,125) THEN 1 ELSE 0 END AS liveindicator
	FROM	bettype WITH (NOLOCK)
	WHERE	typeid IN (1,2,3,4,5,6,7,8,12,13,14,15,16,20,21,24,25,26,27,28,30) 
			OR typeid = 9 OR typeid = 29
			OR (typeid between 121 and 999 AND TypeId < 128)
END

IF @Mode = 2
BEGIN

	INSERT INTO #TmpBettype (typeid, bettypename, type, liveindicator)
	SELECT	typeid , typenamee as bettypename, 0 as type, CASE WHEN typeid IN (1,2,3,5,7,8,12,13,15,24,25,26,27,28) THEN 1 ELSE 0 END AS liveindicator
	FROM	bettype WITH (NOLOCK)
	WHERE	typeid IN (1,2,3,4,5,6,7,8,12,13,14,15,16,20,21,24,25,26,27,28,30) 
			OR (typeid between 121 and 999 AND typeid NOT IN (124,125) AND TypeId < 128)
END

----- number game
IF @Mode IN (1, 3)
BEGIN 
	INSERT INTO #TmpBettype (typeid, bettypename, type, liveindicator)
	SELECT	typeid , typenamee as bettypename, 1 as type, 0 as liveindicator
	FROM	bettype WITH (NOLOCK)
	WHERE	typeid in (81,82,83,84,86,88,90)
	UNION
	SELECT	typeid , typenamee as bettypename, 1 as type, 1 as liveindicator
	FROM	bettype WITH (NOLOCK)
	WHERE	typeid in (85,86,87,89,90) 
END 
 
---- Early KO
IF @Mode = 4
BEGIN

	INSERT INTO #TmpBettype (typeid, bettypename, type, liveindicator)
	SELECT	typeid , typenamee as bettypename, 0 as type, CASE WHEN typeid IN (1,2,3,5,7,8,12,13,15,24,25,26,27,28) THEN 1 ELSE 0 END AS liveindicator
	FROM	bettype WITH (NOLOCK)
	WHERE	typeid IN (1,2,3,4,5,6,7,8,12,13,14,15,16,20,21,24,25,26,27,28,30) 
			OR typeid = 9 
			OR typeid = 29
			OR (typeid between 121 and 999 AND typeid NOT IN (124,125) AND TypeId < 128)
END

SELECT	* 
FROM	#TmpBettype
ORDER BY typeid

-- 


GO
GRANT EXECUTE ON [dbo].[Acc_BetTypeSel] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Acc_BetTypeSel] TO [VNTeam]