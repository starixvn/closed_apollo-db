ALTER  PROCEDURE [dbo].[Acc_BettransSelDelSpecial_MixParlay]
	@MatchID int,
	@bettype smallint = 0,
	@Type smallint = 0, 
	@livehomescore smallint = NULL,
	@liveawayscore smallint = NULL, 
	@FromTransdate Datetime = NULL,
	@ToTransdate Datetime = NULL,
	@hdp smallmoney = 9999,   
	@bettypes varchar(128) = '',   
	@betteam1378 varchar(10) = 'ALL',  
	@betteam515 varchar(10) = 'ALL',  
	@betteam430 varchar(120) = '',  
	@betteam6 varchar(120) = '',  
	@betteam14 varchar(120) = '',  
	@betteam16 varchar(120) = '',  
	@Language NVARCHAR(2) = 'E'  
AS  
/*  
	Created by:  Sophia
	Date:   20130307
	Task: Get transaction of mix parlay bet in bettrans  
	DB: SVRCSD.RepDB
	Original:   
   
	Revisions:   	
	
	Param's Explanation:
			@Type
				0	Dead
				1	Live
				2	All
			@bettype:
				0	All
				9	MixParlay
				29	System parlay

*/  
BEGIN   
	SET NOCOUNT ON  

	CREATE TABLE #ParlayDelete (transid bigint  
        ,SubTransID bigint  
        ,refno bigint  
        ,username varchar(30)  
        ,CustId int  
        ,transdate datetime 
		,actual_stake money
        ,stake money  
        ,winlost money  
        ,odds smallmoney  
        ,OddsType tinyint  
		,bettype smallint
        ,status nvarchar(10)  
        ,spositiontaking smallmoney  
        ,currency tinyint    
        ,choice_Bettype int  
        ,choice_HomeID int  
        ,choice_AwayID int   
        ,choice_hdp1 smallmoney   
        ,choice_hdp2 smallmoney  
        ,choice_Odds smallmoney   
        ,choice_Betteam nvarchar(20)  
        ,choice_Livehomescore smallint  
        ,choice_Liveawayscore smallint  
        ,choice_Liveindicator bit  
        ,choice_LeagueID int  
        ,choice_Sporttype smallint  
        ,choice_isNeutral bit  
        ,choice_matchid int  
        ,choice_matchcode nvarchar(50)  
       )           
	CREATE TABLE #Ref (--id int identity(1,1) primary key clustered   
      refno bigint   
      ,transid bigint        
      ,Bettype int  
      ,hdp1 smallmoney  
      ,hdp2 smallmoney  
      ,odds smallmoney  
      ,betteam nvarchar(20)  
      ,livehomescore smallint  
      ,liveawayscore smallint  
      ,liveindicator bit        
      ,org_betteam nvarchar(10)       
      ,statusID int  
     )  
   
	INSERT INTO #Ref (  
     refno  
     ,transid  
     ,Bettype        
     ,hdp1  
     ,hdp2  
     ,odds  
     ,betteam  
     ,livehomescore  
     ,liveawayscore  
     ,liveindicator  
     ,org_betteam       
     ,statusID  
    )  
 SELECT refno  
  ,transid  
  ,Bettype     
  ,hdp1  
  ,hdp2  
  ,odds  
  ,betteam  
  ,livehomescore  
  ,liveawayscore  
  ,liveindicator  
  ,betteam    
  ,statusID  
 FROM dbo.bettransm AS b WITH(NOLOCK)    
 WHERE	matchid=@MatchID    
		AND CASE WHEN @Type = 2 THEN @Type ELSE b.liveindicator END = @Type
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @Type = 1 THEN @livehomescore ELSE livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @Type = 1 THEN @liveawayscore ELSE liveawayscore END
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @Type = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @Type = 1 THEN @ToTransdate ELSE b.transdate END 
 
   
 CREATE CLUSTERED INDEX cl_Ref_refno ON #Ref(refno)  
 CREATE NONCLUSTERED INDEX nl_Ref_StatusID ON #Ref(StatusID)  
 CREATE NONCLUSTERED INDEX nl_Ref_bettype_betteam ON #Ref(bettype,org_betteam)  
   
 --REMOVE REDUNDANT item  
 DELETE #Ref  
 WHERE statusID NOT IN (0,1,103)  
   
 DELETE r  
 FROM #Ref AS r   
  LEFT JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=r.bettype  
 WHERE bt.val IS NULL -- remove unselected bettypes  
    
 IF @betteam1378<>'All'  
  DELETE r  
  FROM #Ref AS r   
   INNER JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=r.bettype  
  WHERE r.bettype IN (1,3,7,8,2,12) AND (r.org_betteam<>@betteam1378)  
   
 IF @betteam515<>'All'  
  DELETE r  
  FROM #Ref AS r   
   INNER JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=r.bettype  
  WHERE r.bettype in (5,15) AND (r.org_betteam<>@betteam515)  
   
 IF @hdp <> 9999  
  DELETE r  
  FROM #Ref AS r   
   INNER JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=r.bettype  
  WHERE r.bettype IN (1,3,7,8) AND (hdp1<>@hdp-hdp2)  
     
    
 IF @betteam430=''   
  DELETE #Ref  
  WHERE bettype IN (4,30) 
 ELSE IF @betteam430<> 'All'  
  DELETE r  
  FROM #Ref AS r  
   LEFT JOIN dbo.strSplit(@betteam430,'^') AS b4 ON b4.val=r.org_betteam    
  WHERE (r.bettype IN (4,30) AND (b4.val IS NULL))     
   
 IF @betteam6=''  
  DELETE #Ref  
  WHERE bettype=6  
 ELSE IF @betteam6<>'All'   
  DELETE r  
  FROM #Ref AS r    
   LEFT JOIN dbo.strSplit(@betteam6,'^') AS b6 ON b6.val=r.org_betteam    
  WHERE r.bettype=6 AND (b6.val IS NULL)  
   
 IF @betteam14=''  
  DELETE #Ref  
  WHERE bettype=14  
 ELSE IF @betteam14<>'All'   
  DELETE r  
  FROM #Ref AS r    
   LEFT JOIN dbo.strSplit(@betteam14,'^') AS b14 ON b14.val=r.org_betteam    
  WHERE r.bettype=14 AND (b14.val IS NULL)  
   
 IF @betteam16=''  
  DELETE #Ref  
  WHERE bettype=16  
 ELSE IF @betteam16<>'All'   
  DELETE r  
  FROM #Ref AS r    
   LEFT JOIN dbo.strSplit(@betteam16,'^') AS b16 ON b16.val=r.org_betteam    
  WHERE r.bettype=16 AND (b16.val IS NULL)  
     
 INSERT INTO #ParlayDelete  
 SELECT   
   b.transid,  
   r.transid AS SubTransID,  
   r.refno,  
   b.username,  
   b.CustId,  
   b.transdate,
   b.actual_stake,     
   b.stake as StakePositiontaking,  
   b.winlost-b.actual_stake AS winlost,  
   b.odds,     
   b.OddsType,
   b.bettype,   
   b.status,  
   b.tpositiontaking,  
   b.currency,       
   r.bettype AS choice_bettype  
   ,m.homeid  
   ,m.awayid  
   ,r.hdp1 AS choice_hdp1  
   ,r.hdp2 AS choice_hdp2  
   ,r.odds AS choice_odds  
   ,r.betteam  
   ,r.livehomescore  
   ,r.liveawayscore  
   ,r.liveindicator  
   ,m.leagueid  
   ,m.sporttype  
   ,m.isNeutral  
   ,m.matchID  
   ,m.matchCode  
 FROM dbo.bettrans AS b with (NOLOCK)  
  INNER JOIN #Ref AS r WITH(NOLOCK) ON b.refno=r.refno
  INNER JOIN dbo.match AS m WITH(NOLOCK) ON m.matchid=@MatchID  
  WHERE ((@bettype = 0 and b.matchid in (9,29)) OR b.matchid = @bettype ) 
	AND ((@bettype = 0 AND b.bettype IN (9,29)) OR b.bettype = @bettype) 
	AND (b.betid = 0 OR b.betid IS NULL)


 SELECT *
 FROM #ParlayDelete WITH (NOLOCK)    
 ORDER BY transid  
      
 DROP TABLE #ParlayDelete  
 DROP TABLE #Ref  
     
     
 SET NOCOUNT OFF  
END  





GO
GRANT EXECUTE ON [dbo].[Acc_BettransSelDelSpecial_MixParlay] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Acc_BettransSelDelSpecial_MixParlay] TO [vnteam]