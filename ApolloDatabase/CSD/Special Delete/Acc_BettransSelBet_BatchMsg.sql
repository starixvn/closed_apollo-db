 
/****** Object:  StoredProcedure [dbo].[Acc_BettransSelBet_BatchMsg]    Script Date: 4/1/2013 10:34:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Acc_BettransSelBet_BatchMsg]
@transids varchar(8000)
AS
SET NOCOUNT ON
/*
    Created by: Sophia
	Date: 20130328 
	Original: [Acc_BettransSelBet_BatchMsg]
	Task: Select batch msg
	DB: SVRCSD.RepDB

	History:
		 
	Explanation's Param:

*/

DECLARE @BetDelete TABLE (transid bigint, custid int, Username varchar(50))

INSERT INTO @BetDelete (transid, custid, Username)	

SELECT B.TransId, B.CustId as TargetID, B.Username
FROM bettrans B with (nolock)
WHERE transid in ( SELECT convert(varchar,val) FROM dbo.strSplit(@transids,',') )


SELECT  B.TransId, A.AgentID as TargetID, A.Username as TargetName, 1 as IsAgent
FROM	@BetDelete B
INNER JOIN Bettrans_Agent A WITH (NOLOCK)
		ON A.TransID = B.TransID
UNION ALL
SELECT  B.TransId, B.CustId as TargetID, B.Username as TargetName, 0 as IsAgent
FROM	@BetDelete B



