ALTER PROCEDURE [dbo].[Admin_Calculate_22]
	@matchid int,
	@bettype smallint,
	@ResultString nvarchar(50),
	@betcount int = 0
AS
IF @betcount = 0 AND @@SERVERNAME NOT LIKE N'DBIOM%' RETURN

/*
Created by: Dan
Date: 2013-03-15
Task : Settlement for Next Goal Bettype  
DB: SVRTXN/TransDB
Revisions:    
	- 20131125@Dan: use temp variable instead of temp tables to prevent problem when executing via replication
	- 20140226@Sophia: Calculate Comm with new formula

Param's Explanation:
• @ResultString: + get from match.GoalRecord,
                 + uses nvarchar to avoid problem compare with varchar from betteam

*/
--IF @@SERVERNAME IN ('DB04', 'DB042', 'DB043', 'DB044') RETURN

DECLARE @modds SMALLMONEY, @commWinRate SMALLMONEY, @commLostRate SMALLMONEY

DECLARE @hdp SMALLMONEY

	
DECLARE @ba table (
	transid bigint , 
	AgentId int, 
	DoubleCommLosing bit, 
	odds smallmoney, 
	Stake money, 
	Actual_Stake money,
	AWinLost money,
	AComm money,
	APositionTaking smallmoney, 
	ADiscount decimal(9,8), 
	downlinePT smallmoney, 
	hdp1 smallmoney, 
	hdp2 smallmoney,	
	livehomescore smallint, 	
	liveawayscore smallint, 
	betteam varchar(10), 
	bettype smallint, 
	Status varchar(10), 
	StatusId tinyint
	)

--get the needed data to settle for agent
INSERT INTO @ba (
	transid , 
	AgentId , 
	DoubleCommLosing , 
	odds , 
	Stake, 
	Actual_Stake ,
	AWinLost ,
	AComm ,
	APositionTaking , 
	ADiscount , 
	downlinePT, 
	hdp1 , 
	hdp2 ,	
	livehomescore , 	
	liveawayscore , 
	betteam , 
	bettype, 
	Status , 
	StatusId
	)

SELECT ba.transid, 
	ba.[AgentId], 		
	b.[DoubleCommLosing], 
	b.odds, 
	b.[Stake], 
	b.[Actual_Stake],
	AWinLost,AComm,APositionTaking, ADiscount, 
	SUM(ba.APositionTaking) OVER (PARTITION BY ba.transid
					ORDER BY agentlevel DESC
					ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS downlinePT, 
	hdp1, hdp2,	livehomescore, 	liveawayscore, betteam, b.bettype, b.Status, b.StatusId	
FROM BetTrans B WITH (NOLOCK) JOIN BetTrans_Agent ba WITH (NOLOCK) ON 
	b.TransId=ba.TransId and ba.matchid=b.matchid AND ba.bettype=b.bettype 
	JOIN AgentInfo a WITH (NOLOCK) ON a.AgentID=ba.AgentID
WHERE
	b.matchid=@matchid AND
	b.bettype=@bettype AND		
	--[status] NOT IN (N'VOID', N'REJECT')
	b.statusID NOT IN (101,102)	

-- settle for agent in temporary table
UPDATE @ba 
SET 
	@hdp = CASE betteam
		    WHEN N'h' THEN hdp2-hdp1 
		    WHEN N'a' THEN hdp1-hdp2
		    END,

	@modds = CASE SUBSTRING(@ResultString, livehomescore + liveawayscore + 1, 1)
		WHEN N'' THEN @hdp 
		WHEN betteam THEN 1 + @hdp
		ELSE -1 + @hdp
	END,
			
	@commWinRate = CASE [DoubleCommLosing]  -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
	WHEN 0 THEN 1
	WHEN 1 THEN 0 
	ELSE 1 END,
	@commLostRate = CASE [DoubleCommLosing]
	WHEN 0 THEN 1
	WHEN 1 THEN 2 
	ELSE 1 END,--'s','m'
				
	aWinLost = CASE
		WHEN @modds >  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -apositiontaking
		WHEN @modds =  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -apositiontaking * 0.5
		WHEN @modds =  0	THEN 0
		WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
		WHEN @modds < -0.25	THEN actual_stake * apositiontaking
		END,
					
	aComm = CASE
		WHEN @modds >  0.25 	THEN @commWinRate * adiscount * (1-DownlinePT) * dbo.[F_GetCommBase] (Stake, Odds, Bettype, @MOdds)
		WHEN @modds =  0.25 	THEN @commWinRate * adiscount * (1-DownlinePT) * dbo.[F_GetCommBase] (Stake, Odds, Bettype, @MOdds)
		WHEN @modds =  0    	THEN 0
		WHEN @modds = -0.25 	THEN @commLostRate * adiscount * (1-DownlinePT) * dbo.[F_GetCommBase] (Stake, Odds, Bettype, @MOdds)
		WHEN @modds < -0.25 	THEN @commLostRate * adiscount * (1-DownlinePT) * dbo.[F_GetCommBase] (Stake, Odds, Bettype, @MOdds)
		END,
	
		
	Status = CASE
		WHEN @modds > 0 THEN 'WON'
		WHEN @modds = 0 THEN 'DRAW'
		WHEN @modds < 0 THEN 'LOSE'
		END,
	StatusID = CASE
		WHEN @modds > 0 THEN 112 --WON
		WHEN @modds = 0 THEN 111 --DRAW
		WHEN @modds < 0 THEN 113 --LOSE
		END			
	
		
--settle for BetTrans_Agent
UPDATE BetTrans_Agent with (ROWLOCK, UPDLOCK)
SET aWinLost = tmp_ba.AWinLost,
	aComm = tmp_ba.aComm,			
	Status = tmp_ba.Status,
	StatusID = tmp_ba.StatusId			
FROM BetTrans_Agent 
		INNER JOIN @ba tmp_ba ON BetTrans_Agent.TransId = tmp_ba.TransId AND BetTrans_Agent.AgentId = tmp_ba.AgentId
WHERE BetTrans_Agent.matchid=@matchid AND
	BetTrans_Agent.bettype=@bettype AND
	BetTrans_Agent.statusID NOT IN (101,102)

--settle for BetTrans
UPDATE BetTrans with (ROWLOCK, UPDLOCK)
SET							
	@hdp = CASE betteam
		    WHEN N'h' THEN hdp2-hdp1 
		    WHEN N'a' THEN hdp1-hdp2
		    END,
	@modds = modds = CASE SUBSTRING(@ResultString, livehomescore + liveawayscore + 1, 1)
		WHEN N'' THEN @hdp 
		WHEN betteam THEN 1 + @hdp
		ELSE -1 + @hdp
	END,
			
	@commWinRate = CASE [DoubleCommLosing]  -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
	WHEN 0 THEN 1
	WHEN 1 THEN 0 
	ELSE 1 END,
	@commLostRate = CASE [DoubleCommLosing]
	WHEN 0 THEN 1
	WHEN 1 THEN 2 
	ELSE 1 END,--'s','m'
				
	WinLost = CASE
		WHEN @modds >  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end)
		WHEN @modds =  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * 0.5
		WHEN @modds =  0	THEN actual_stake
		WHEN @modds = -0.25	THEN actual_stake * 0.5
		WHEN @modds < -0.25	THEN 0
		END,
					
	PlayerComm = CASE
		WHEN @modds >  0.25 	THEN @commWinRate * playerdiscount * dbo.[F_GetCommBase] (Stake, Odds, Bettype, @MOdds)
		WHEN @modds =  0.25 	THEN @commWinRate * playerdiscount * dbo.[F_GetCommBase] (Stake, Odds, Bettype, @MOdds)
		WHEN @modds =  0    	THEN 0
		WHEN @modds = -0.25 	THEN @commLostRate * playerdiscount * dbo.[F_GetCommBase] (Stake, Odds, Bettype, @MOdds)
		WHEN @modds < -0.25 	THEN @commLostRate * playerdiscount * dbo.[F_GetCommBase] (Stake, Odds, Bettype, @MOdds)
		END, 
		
	Status = CASE
		WHEN @modds > 0 THEN 'WON'
		WHEN @modds = 0 THEN 'DRAW'
		WHEN @modds < 0 THEN 'LOSE'
		END,
	StatusID = CASE
		WHEN @modds > 0 THEN 112 --WON
		WHEN @modds = 0 THEN 111 --DRAW
		WHEN @modds < 0 THEN 113 --LOSE
		END,
	ruben=1,
	[TWinLost] = AgentWinlost.AWinlost,
	[TComm] =  CASE
			WHEN @modds >  0.25 	THEN @commWinRate * Tdiscount * (1-[TPositionTaking]) * dbo.[F_GetCommBase] (Stake, Odds, Bettype, @MOdds)
			WHEN @modds =  0.25 	THEN @commWinRate * Tdiscount * (1-[TPositionTaking]) * dbo.[F_GetCommBase] (Stake, Odds, Bettype, @MOdds)
			WHEN @modds =  0    	THEN 0
			WHEN @modds = -0.25 	THEN @commLostRate * Tdiscount * (1-[TPositionTaking]) * dbo.[F_GetCommBase] (Stake, Odds, Bettype, @MOdds)
			WHEN @modds < -0.25 	THEN @commLostRate * Tdiscount * (1-[TPositionTaking]) * dbo.[F_GetCommBase] (Stake, Odds, Bettype, @MOdds)
			END
	 
FROM 
	(	SELECT TransId, sum(AWinLost) aWinlost
		FROM @ba 
		GROUP BY TransId) AgentWinlost 
WHERE
	AgentWinlost.TransID=BetTrans.TransId AND
	BetTrans.matchid=@matchid AND
	BetTrans.bettype=@bettype AND
	--[status] NOT IN (N'VOID', N'REJECT')
	BetTrans.statusID NOT IN (101,102)


GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_22] TO [aplweb]