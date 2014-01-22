USE [ReportDB]
GO
/****** Object:  StoredProcedure [dbo].[GEN_rptBetting]    Script Date: 10/11/2013 9:31:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[GEN_rptBetting]
    @date datetime, 
    @date2 datetime = null
AS


/*
Created: 20131009@winnie
Task: Generate data into rpt_Betting 
DB: KPIReport

Revisions:
- 20140122@Sophia: Add PlayerComm

Param's Explanation:

*/
IF @date2 IS NULL SET @date2 = @date
SET @date2 = DATEADD(day,1,@date2)

	SELECT  b.winlostdate,       
			b.bettype,
			CASE 
				WHEN b.bettype=9 THEN -9 
				WHEN b.bettype=29 THEN -29 
				--- WHEN b.bettype = 10 OR (b.bettype>30 AND b.bettype<50) THEN ISNULL(o.leagueid,-1)           
				WHEN b.bettype = 10 THEN ISNULL(o.leagueid,-1)  
				ELSE ISNULL(m.leagueid,-1) 
			END AS leagueid,	
			b.currency,
			b.statusid Status,	
			b.LiveIndicator, 
			COUNT(*) Betcount,
			COUNT(DISTINCT b.custid) MemberCount,
			SUM(stake) Turnover,
			SUM(winlost-actual_stake) winloss,
			SUM(PlayerComm) PlayerComm,
			SUM(Twinlost) Twinloss,	  
			SUM(Tcomm) Tcommission
	INTO #TMP
	FROM
	    dbo.bettrans b (NOLOCK) 	  
	    LEFT JOIN dbo.match m (NOLOCK) ON b.matchid = m.matchid
	    LEFT JOIN dbo.outright o (NOLOCK) ON b.matchid = o.matchid	  
   
    GROUP BY
	    b.winlostdate,	  
	    b.bettype,
        CASE 
            WHEN b.bettype=9 THEN -9 
			WHEN b.bettype=29 THEN -29 
            --- WHEN b.bettype = 10 OR (b.bettype>30 AND b.bettype<50) THEN ISNULL(o.leagueid,-1)           
		    WHEN b.bettype = 10 THEN ISNULL(o.leagueid,-1) 
            ELSE ISNULL(m.leagueid,-1) 
        END,	
	    b.currency,
	    b.statusid,
		b.LiveIndicator
	  

DELETE FROM dbo.rpt_Betting
WHERE rptDate>=@date AND rptDate<@date2

INSERT INTO dbo.rpt_Betting
        ([rptDate]      
        ,[Bettype]
        ,[LeagueID]
        ,[CurrencyID]
        ,[Status] 
		,[IsLive]
        ,[BetCount]
        ,[MemberCount]
        ,[Turnover]
        ,[WinLoss]
		,[PlayerComm]
        ,[TWinLoss]     
        ,[TCommission]
     )
 SELECT  winlostdate,       
		 bettype,
		 leagueid,	
		 currency,
		 Status,
		 LiveIndicator,	 
		 Betcount,
		 MemberCount,
		 Turnover,
		 Winloss,
		 PlayerComm,
		 Twinloss,	  
		 Tcommission
 FROM    #TMP 
	  


