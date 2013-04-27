ALTER PROCEDURE [dbo].[Admin_Calculate_2] 
	@matchid int,
	@bettype smallint,
	@oddeven smallmoney,
	@betcount int = 0
	-- add any params, please modify script in 'special section'
AS
IF @betcount = 0 AND @@SERVERNAME NOT LIKE N'DBIOM%' RETURN

/*
	Created by: Dan
	Date: 2013-03-15
	Task: Settlement 
	DB: SVRTXN/TransDB
	
	Revisions:
		
*/
IF @@SERVERNAME IN ('DB04', 'DB042', 'DB043', 'DB044') RETURN


	Declare @modds smallmoney, @commWinRate smallmoney, @commLostRate smallmoney, @DownlinePT smallmoney

	--IF @@SERVERNAME IN ('DB052', 'DB053', 'DB054')
	--BEGIN
	--	--================================ 
	--	--Special section
	--	DECLARE @sqlCommand NVARCHAR(MAX),
	--			@execID INT

	--	SELECT @sqlCommand = 'EXEC [dbo].[Admin_Calculate_2_external] @matchid = ' + CONVERT(NVARCHAR(10),@matchid) +
	--						 ', @bettype = ' + CONVERT(NVARCHAR(10),@bettype) +
	--						 ', @oddeven = ' + CONVERT(NVARCHAR(10),@oddeven)
							 
	--	INSERT INTO Acc_Externalsettlement(SPName, SQLCommand, CreatedDate, StatusID, MatchID, Bettype, Status,BetCount)
	--				VALUES('Admin_Calculate_2',@sqlCommand,GETDATE(), 0, @matchid, @bettype, 'waiting',@betcount )

	--	RETURN
	--	-- end Sepcial section
	--	--=================================
	--END
	
	--get the needed data to settle for agent
	SELECT ba.transid, ba.[AgentId], [AgentLevel], b.[DoubleCommLosing], b.odds, b.[Stake], b.[Actual_Stake],
		AWinLost,AComm,APositionTaking, ADiscount, cast(0 as smallmoney) as DownlinePT, 
		hdp1, hdp2,	livehomescore, 	liveawayscore, betteam, ba.bettype, ba.Status, ba.StatusId
	INTO #ba 
	FROM BetTrans B WITH (NOLOCK) JOIN BetTrans_Agent ba WITH (NOLOCK) ON 
		b.TransId=ba.TransId and ba.matchid=b.matchid AND ba.bettype=b.bettype 
		JOIN AgentInfo a WITH (NOLOCK) ON a.AgentID=ba.AgentID
	WHERE
		b.matchid=@matchid AND
		b.bettype=@bettype AND
			
		--[status] NOT IN (N'VOID', N'REJECT')
		b.statusID NOT IN (101,102)
		
	--create index		
	CREATE CLUSTERED INDEX IX_tmp on #ba (transid,AgentLevel desc)	
	--CREATE INDEX IX_tmp on #ba (transid,[AgentLevel]) INCLUDE (APositionTaking)	
		
	DECLARE @prevtransid BIGINT =0 
	
	-- settle for agent in temporary table
	UPDATE #ba 
	SET 
		@DownlinePT=DownlinePT = case when @prevtransid <> transid 
						then APositionTaking
						else APositionTaking + @DownlinePT -- accumulated PT for upper agent --> for calculating agent commision
						end,
		@prevtransid = transid,			
		
		@modds =  CASE
			WHEN betteam = 'h' AND @oddeven = 1 THEN 1
			WHEN betteam = 'a' AND @oddeven = 0 THEN 1
			ELSE -1
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
			WHEN @modds >  0.25 	THEN @commWinRate * adiscount * stake * (1-@DownlinePT)
			WHEN @modds =  0.25 	THEN @commWinRate * adiscount * stake * (1-@DownlinePT) * 0.5
			WHEN @modds =  0    	THEN 0
			WHEN @modds = -0.25 	THEN @commLostRate * adiscount * stake * (1-@DownlinePT) * 0.5
			WHEN @modds < -0.25 	THEN @commLostRate * adiscount * stake * (1-@DownlinePT)
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
	OPTION (MAXDOP 1) --should use this for quirky update to avoid parallelism problem	
		
	--settle for BetTrans_Agent
	UPDATE BetTrans_Agent with (ROWLOCK, UPDLOCK)
	SET aWinLost = #ba.AWinLost,
		aComm = #ba.aComm,			
		Status = #BA.Status,
		StatusID = #ba.StatusId			
	FROM BetTrans_Agent 
			join #ba ON BetTrans_Agent.TransId = #ba.TransId AND BetTrans_Agent.AgentId = #ba.AgentId
	WHERE BetTrans_Agent.matchid=@matchid AND
		BetTrans_Agent.bettype=@bettype AND
		BetTrans_Agent.statusID NOT IN (101,102)

	--settle for BetTrans
	UPDATE BetTrans with (ROWLOCK, UPDLOCK)
	SET							
		@modds = modds = CASE
		WHEN betteam = 'h' AND @oddeven = 1 THEN 1
		WHEN betteam = 'a' AND @oddeven = 0 THEN 1
		ELSE -1
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
			WHEN @modds >  0.25 	THEN @commWinRate * playerdiscount * stake
			WHEN @modds =  0.25 	THEN @commWinRate * playerdiscount * stake * 0.5
			WHEN @modds =  0    	THEN 0
			WHEN @modds = -0.25 	THEN @commLostRate * playerdiscount * stake * 0.5
			WHEN @modds < -0.25 	THEN @commLostRate * playerdiscount * stake
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
				WHEN @modds >  0.25 	THEN @commWinRate * Tdiscount * stake * (1-[TPositionTaking])
				WHEN @modds =  0.25 	THEN @commWinRate * Tdiscount * stake * (1-[TPositionTaking]) * 0.5
				WHEN @modds =  0    	THEN 0
				WHEN @modds = -0.25 	THEN @commLostRate * Tdiscount * stake * (1-[TPositionTaking]) * 0.5
				WHEN @modds < -0.25 	THEN @commLostRate * Tdiscount * stake * (1-[TPositionTaking])
				END
	from 
		(SELECT TransId, sum(AWinLost) aWinlost
			FROM #ba 
			GROUP BY TransId) AgentWinlost 
	WHERE
		AgentWinlost.TransID=BetTrans.TransId AND
		BetTrans.matchid=@matchid AND
		BetTrans.bettype=@bettype AND
		--[status] NOT IN (N'VOID', N'REJECT')
		BetTrans.statusID NOT IN (101,102)

GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_1] TO [aplweb]