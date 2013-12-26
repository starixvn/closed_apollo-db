ALTER PROCEDURE [dbo].[Admin_Calculate_10]
	@matchid int,
	@status nvarchar(10),
	@deadheat float = 1,
	@winlostdate smalldatetime = NULL
	
AS
/*
Created: 
Task : execRep sp for outright settlement

DB: DBTRANS.bodb02
Original: 

Revisions:	
	- 20131125@Dan: add undo action
Param's Explanation:

*/
SET NOCOUNT ON

DECLARE @commWinRate SMALLMONEY, @commLostRate SMALLMONEY
-- @deadheat = fraction of deadheat to divide (1,2,3  etc)

if @winlostdate IS NULL
BEGIN
	select @winlostdate = convert(char(10),getdate(),111)
END

	
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

IF (@status in ('won','lose'))
BEGIN
	
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
		b.bettype=10 AND		
		--[status] NOT IN (N'VOID', N'REJECT')
		b.statusID NOT IN (101,102)	
END

if (@status='won')
begin
	-- settle for agent in temporary table
	UPDATE @ba
	SET 			
		@commWinRate = CASE [DoubleCommLosing]  -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
							WHEN 0 THEN 1
							WHEN 1 THEN 0 
							ELSE 1 
						END,						
		aWinLost = -(odds-1) * apositiontaking * stake / @deadheat,					
		aComm = @commWinRate * (1-DownlinePT) * adiscount * stake,				
		[status] = 'WON',			
		statusID = 112				
			
	--settle for BetTrans_Agent
	UPDATE BetTrans_Agent with (ROWLOCK, UPDLOCK)
	SET aWinLost = tmp_ba.AWinLost,
		aComm = tmp_ba.aComm,			
		Status = tmp_ba.Status,
		StatusID = tmp_ba.StatusId,		
		winlostdate = @winlostdate			
	FROM BetTrans_Agent 
			INNER JOIN @ba tmp_ba ON BetTrans_Agent.TransId = tmp_ba.TransId AND BetTrans_Agent.AgentId = tmp_ba.AgentId
	WHERE BetTrans_Agent.matchid=@matchid AND
		BetTrans_Agent.bettype=10 AND
		BetTrans_Agent.statusID NOT IN (101,102)

	--settle for BetTrans
	UPDATE BetTrans with (ROWLOCK, UPDLOCK)
	SET										
		@commWinRate = CASE [DoubleCommLosing]  -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
							WHEN 0 THEN 1
							WHEN 1 THEN 0 
							ELSE 1 
						END,				
		WinLost = (((odds-1)/@deadheat)+1) * stake ,			
		PlayerComm = @commWinRate * playerdiscount * stake,				
		Status = 'WON',
		StatusID = 112,			
		ruben=1,
		winlostdate = @winlostdate, --convert(char(10),getdate(),111),
		statuswinlost = 2,
		[TWinLost] = AgentWinlost.AWinlost,
		[TComm] =  @commWinRate * Tdiscount * stake * (1-[TPositionTaking])				
	FROM 
		(	SELECT TransId, sum(AWinLost) aWinlost
			FROM @ba 
			GROUP BY TransId) AgentWinlost 
	WHERE
		AgentWinlost.TransID=BetTrans.TransId AND
		BetTrans.matchid=@matchid AND
		BetTrans.bettype=10 AND
		--[status] NOT IN (N'VOID', N'REJECT')
		BetTrans.statusID NOT IN (101,102)
end 
else if (@status='lose')
begin		
	-- settle for agent in temporary table
	UPDATE @ba 
	SET 		
		@commLostRate = CASE [DoubleCommLosing]
							WHEN 0 THEN 1
							WHEN 1 THEN 2 
							ELSE 1 
						END,--'s','m'							
		awinlost = apositiontaking * stake,			
		aComm = @commLostRate * adiscount * stake * (1-DownlinePT),		
		[status] = 'LOSE',			
		statusID = 113	
			
	--settle for BetTrans_Agent
	UPDATE BetTrans_Agent with (ROWLOCK, UPDLOCK)
	SET aWinLost = tmp_ba.AWinLost,
		aComm = tmp_ba.aComm,			
		Status = tmp_ba.Status,
		StatusID = tmp_ba.StatusId,		
		winlostdate = @winlostdate				
	FROM BetTrans_Agent 
			INNER JOIN @ba tmp_ba ON BetTrans_Agent.TransId = tmp_ba.TransId AND BetTrans_Agent.AgentId = tmp_ba.AgentId
	WHERE BetTrans_Agent.matchid=@matchid AND
		BetTrans_Agent.bettype=10 AND
		BetTrans_Agent.statusID NOT IN (101,102)

	--settle for BetTrans
	UPDATE BetTrans with (ROWLOCK, UPDLOCK)
	SET										
		@commLostRate = CASE [DoubleCommLosing]
		WHEN 0 THEN 1
		WHEN 1 THEN 2 
		ELSE 1 END,--'s','m'	
				
		WinLost = 0,		
		PlayerComm = @commLostRate * playerdiscount * stake,		
		Status = 'LOSE',
		StatusID = 113,			
		ruben=1,
		winlostdate = @winlostdate, --convert(char(10),getdate(),111),
		statuswinlost = 4,
		[TWinLost] = AgentWinlost.AWinlost,
		[TComm] =  @commLostRate * Tdiscount * stake * (1-[TPositionTaking])					
	FROM 
		(	SELECT TransId, sum(AWinLost) aWinlost
			FROM @ba 
			GROUP BY TransId) AgentWinlost 
	WHERE
		AgentWinlost.TransID=BetTrans.TransId AND
		BetTrans.matchid=@matchid AND
		BetTrans.bettype=10 AND
		--[status] NOT IN (N'VOID', N'REJECT')
		BetTrans.statusID NOT IN (101,102)
	
end
ELSE IF @status = 'Refund'
BEGIN
	UPDATE dbo.bettrans with (updlock,rowlock)
	SET	[status] = 'Refund',
		ruben = 1 ,
		winlostdate = @winlostdate,
		statuswinlost = 4,		
		winlost = actual_stake,		
		playercomm = 0,
		statusID = 103,
		TWinLost=0,TComm=0
	where matchid = @matchid and bettype = 10 and statusID NOT IN (101, 102) -- 101:reject, 102:void

	UPDATE dbo.BetTrans_Agent with (ROWLOCK, UPDLOCK)
	SET
		status = 'Refund',
		statusID = 103,
		awinlost=0,
		acomm=0,
		winlostdate = @winlostdate	
	where
		matchid=@matchid
		and bettype = 10 and statusID NOT IN (101, 102) -- 101:reject, 102:void
END
ELSE IF @status = 'UNDO'
BEGIN
	UPDATE bettrans WITH (ROWLOCK, UPDLOCK)
	SET
		ruben = 0, status = 'running', statusID = 0,
		statuswinlost = NULL,
		winlost = 0, TWinLost=0,
		playercomm = 0, TComm=0
	WHERE matchid = @matchid AND 
		bettype=10 AND		
		--status NOT IN ('running','waiting','void','reject')
		statusID NOT IN (0,1,102,101)

	UPDATE dbo.BetTrans_Agent with (ROWLOCK, UPDLOCK)
	SET
		status = 'running', statusID = 0,
		awinlost = 0, acomm = 0
	WHERE
		 matchid = @matchid AND 
		 bettype=10 AND		
		--status NOT IN ('running','waiting','void','reject')
		statusID NOT IN (0,1,102,101)
END
GO
--GRANT EXECUTE ON [dbo].[Admin_Calculate_10] TO [ibc_admin]
GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_10] TO [aplweb]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_10] TO [vnteam]