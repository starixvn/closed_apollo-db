USE [ReportDB]
GO
/****** Object:  StoredProcedure [dbo].[Task_PrepareStaging]    Script Date: 10/11/2013 8:52:26 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_PrepareStaging]  
    @datefrom smalldatetime=null
    ,@dateto smalldatetime=null
WITH RECOMPILE
AS  
/*
Created: 20131009@winnie
Task: 
DB: KPIReport

Revisions:

Param's Explanation:
*/
BEGIN
	
	DECLARE @today datetime, @thedaybefore datetime
	SELECT @today=@dateto, @thedaybefore=@datefrom
	
    IF (NOT (@today IS NULL OR @thedaybefore IS NULL))
        SELECT @today=CONVERT(varchar(10),DATEADD(day,1,@today),120), @thedaybefore=CONVERT(varchar(10),@thedaybefore,120)
    ELSE
        SELECT @today=CONVERT(varchar(10),current_timestamp,120), @thedaybefore=DATEADD(day,-3,@today)

    ---------PROCESS OUTRIGHT DATA--------------------------------------------------------------------------------------------    
	TRUNCATE TABLE dbo.outright    
   
    INSERT INTO dbo.outright(matchid, leagueid)  
    SELECT orid AS matchid, leagueid  
        FROM RepDB.dbo.outright WITH (NOLOCK)  
        WHERE eventdate>=@thedaybefore AND eventdate<@today  
        UNION   
        SELECT orid AS matchid, leagueid  
        FROM RepDB.dbo.outright14 WITH (NOLOCK)  
        WHERE eventdate>=@thedaybefore AND eventdate<@today  
  
	---------PROCESS MATCH DATA--------------------------------------------------------------------------------------------    
	 TRUNCATE TABLE dbo.match    
   
	 INSERT INTO dbo.match(matchid, leagueid)  
     SELECT matchid, leagueid  
        FROM RepDB.dbo.match WITH (NOLOCK)  
        WHERE eventdate>=@thedaybefore AND eventdate<@today  
        UNION  
        SELECT matchid, leagueid  
        FROM RepDB.dbo.match14 WITH (NOLOCK)  
        WHERE eventdate>=@thedaybefore AND eventdate<@today  
     
	---------PROCESS BETTRANS DATA--------------------------------------------------------------------------------------------  
	TRUNCATE TABLE dbo.[bettrans]  
	        
    DECLARE @count int,@movebetdate smalldatetime,@tmpDate smalldatetime
	SELECT @count=DATEDIFF(DAY,@thedaybefore,@today) - 1
	SELECT @movebetdate=MAX(winlostdate) FROM RepDB.dbo.bettrans14 WITH (NOLOCK)

	WHILE (@count>=0)
	BEGIN
		SELECT @tmpDate=DATEADD(DAY,@count,@thedaybefore)
		
		IF (@tmpDate > @movebetdate)
		BEGIN
			--Copy LIVE data (bettrans)             
			INSERT INTO dbo.bettrans
			    ([transid]
                ,winlostdate              
                ,bettype
                ,[custid]
                ,[stake]
                ,actual_stake
                ,[winlost]
				,[Twinlost]
                ,Tcomm
                ,matchid
                ,[status]               
                ,currency              
                ,transdate
                ,statusid
				,LiveIndicator
               )
			SELECT 
			    b.transid,
	            b.winlostdate,	          
	            b.bettype,
	            b.custid,
	            ABS(b.stake) stake,
	            b.actual_stake,
	            b.winlost,
				b.TWinLost,
	            b.Tcomm,
	            b.matchid,
	           --- CASE WHEN (b.bettype IN (1, 3, 7, 8, 17, 18, 124, 125) AND ABS(b.modds) = 0.25 AND [status] IN('WON', 'LOSE')) OR (b.bettype IN (33,43) AND [status] <> 'refund' AND b.liveawayscore=0) THEN 'HALF ' ELSE '' END + b.status AS [status],
			    CASE WHEN (b.bettype IN (1, 3, 7, 8, 17, 18, 124, 125) AND ABS(b.modds) = 0.25 AND [status] IN('WON', 'LOSE'))   THEN 'HALF ' ELSE '' END + b.status AS [status],
                b.currency,              
                b.transdate,               
                b.statusid,
				b.LiveIndicator            
			FROM RepDB.dbo.bettrans b WITH (NOLOCK)			    
			WHERE b.bettype<19000
			    AND b.statusid NOT IN (0,101,102,121)  -- 'void', 'reject', 'running','done'
	            AND b.winlostdate=@tmpDate
				AND b.TransID NOT IN  (		SELECT	TransID 
											FROM	RepDb.dbo.Bettrans_Agent WITH (NOLOCK)
											WHERE	winlostdate = @tmpDate			 
													AND statusID not in (0,101,102,121)  
													AND bettype < 19001
													AND AgentID = 53288 -----line test Suntest
									   ) 
				AND b.Currency <> 20 
 
            
        END
		ELSE
        BEGIN
			--Copy archived data (bettrans14)
 
			INSERT INTO dbo.bettrans
			    ([transid]
                ,winlostdate              
                ,bettype
                ,[custid]
                ,[stake]
                ,actual_stake
                ,[winlost]
				,Twinlost
                ,Tcomm
                ,matchid
                ,[status]              
                ,currency               
                ,transdate
                ,statusid
				,LiveIndicator
                )
			SELECT 
			    b.transid,	           
	            b.WinLostDate,
	            b.bettype,
	            b.custid,
	            ABS(b.stake) stake,
	            b.actual_stake,
	            b.winlost,
				b.TWinLost,
	            b.Tcomm,
	            b.matchid,
	           ---- CASE WHEN (b.bettype IN (1, 3, 7, 8, 17, 18, 124, 125) AND ABS(b.modds) = 0.25 AND [status] IN('WON', 'LOSE')) OR (b.bettype IN (33,43) AND [status] <> 'refund' AND b.liveawayscore=0) THEN 'HALF ' ELSE '' END + b.status AS [status],
			    CASE WHEN (b.bettype IN (1, 3, 7, 8, 17, 18, 124, 125) AND ABS(b.modds) = 0.25 AND [status] IN('WON', 'LOSE'))  THEN 'HALF ' ELSE '' END + b.status AS [status],
                b.currency,              
                b.transdate,               
                b.statusid,
				b.LiveIndicator     
			FROM RepDB.dbo.bettrans14 b WITH (NOLOCK)
			WHERE  b.bettype<19000
			    AND b.statusid NOT IN (0,101,102,121)  -- 'void', 'reject', 'running','done'
	            AND b.winlostdate=@tmpDate
				AND b.TransID NOT IN  (		SELECT	TransID 
											FROM	RepDb.dbo.Bettrans14_Agent WITH (NOLOCK)
											WHERE	winlostdate = @tmpDate			 
													AND statusID not in (0,101,102,121) 
													AND bettype < 19001
													AND AgentID = 53288 -----line test Suntest
										)
				AND b.Currency <> 20 
					 
        END

		SELECT @count = @count - 1
	END
	
	
	UPDATE dbo.bettrans
	SET statusid=CASE WHEN [status]='HALF WON' THEN 114 WHEN [status]='HALF LOSE' THEN 115 END
	WHERE [status] IN ('HALF WON','HALF LOSE')
	
	--///// PROCESS UPDATE BA STATUS FOR TICKETS ///////////////////
 
END
