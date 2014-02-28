ALTER PROCEDURE [dbo].[Admin_Calculate_4]
	@matchid int,
	@bettype smallint,
	@correctscore nvarchar(10),
	@goaldiff smallmoney,
	@FGLG2 nvarchar(10) = NULL,
	@betcount int = 0
AS
--IF @betcount = 0 AND @@SERVERNAME NOT LIKE N'DBIOM%' RETURN

/*
	Created by: Dan
	Date: 2013-03-15
	Task: Settlement 
	DB: SVRTXN/TransDB
	
	Revisions:
		- 20131125@Dan: use temp variable instead of temp tables to prevent problem when executing via replication
		- 20140226@Sophia: Calculate Comm with new formula
		
*/
--IF @@SERVERNAME IN ('DB04', 'DB042', 'DB043', 'DB044') RETURN

SET NOCOUNT ON
DECLARE @modds SMALLMONEY, @commWinRate SMALLMONEY, @commLostRate SMALLMONEY, @matchdate datetime


--IF @@SERVERNAME IN ('DB052','DB053','DB054')
--BEGIN
--	DECLARE @sqlCommand NVARCHAR(MAX),
--			@execID INT

--	SELECT @sqlCommand = 'EXEC [dbo].[Admin_Calculate_4_external] @matchid = ' + CONVERT(NVARCHAR(10),@matchid) +
--						 ', @bettype = ' + CONVERT(NVARCHAR(10),@bettype) + 
--						 ', @correctscore = ''' + @correctscore + '''' +
--						 ', @goaldiff = ' + CONVERT(NVARCHAR(10),@goaldiff) +
--						 ', @FGLG2 = ''' + ISNULL(@FGLG2,'') + '''' +	
--						 ', @betcount = ' + CONVERT(NVARCHAR(10),ISNULL(@betcount,''))							 
							 
--	INSERT INTO Acc_Externalsettlement(SPName, SQLCommand, CreatedDate, StatusID, MatchID, Bettype, Status, BetCount)
--				VALUES('Admin_Calculate_4',@sqlCommand,GETDATE(), 0, @matchid, @bettype, 'waiting',@betcount)
							
--	RETURN
--END
	
--ELSE 
BEGIN
		
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
		sum(ba.APositionTaking) OVER (PARTITION BY ba.transid
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
		@modds = CASE
			WHEN (betteam = @correctscore OR betteam = @FGLG2) THEN 1
			WHEN betteam = '4:0' AND @goaldiff >=  4 and @bettype=30 THEN 1 -- 4UP for 1st Correct Score
			WHEN betteam = '0:4' AND @goaldiff <=  -4 and @bettype=30 THEN 1 -- 4UP for 1st Correct Score
			WHEN betteam = '5:0' AND @goaldiff >=  5 THEN 1
			WHEN betteam = '0:5' AND @goaldiff <= -5 THEN 1
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
			WHEN @modds >  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,1204) then odds-1 else odds end) end) * -apositiontaking
			WHEN @modds =  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,1204) then odds-1 else odds end) end) * -apositiontaking * 0.5
			WHEN @modds =  0	THEN 0
			WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
			WHEN @modds < -0.25	THEN actual_stake * apositiontaking
			END,
					
		aComm = CASE
			WHEN @modds >  0.25 	THEN @commWinRate * adiscount * (1-DownlinePT) * dbo.[F_GetCommBase] (Stake,Odds,Bettype,@modds)
			WHEN @modds =  0.25 	THEN @commWinRate * adiscount * (1-DownlinePT) * dbo.[F_GetCommBase] (Stake,Odds,Bettype,@modds)
			WHEN @modds =  0    	THEN 0
			WHEN @modds = -0.25 	THEN @commLostRate * adiscount * (1-DownlinePT) * dbo.[F_GetCommBase] (Stake,Odds,Bettype,@modds)
			WHEN @modds < -0.25 	THEN @commLostRate * adiscount * (1-DownlinePT) * dbo.[F_GetCommBase] (Stake,Odds,Bettype,@modds)				
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
		@modds = modds = CASE
			WHEN (betteam = @correctscore OR betteam = @FGLG2) THEN 1
			WHEN betteam = '4:0' AND @goaldiff >=  4 and @bettype=30 THEN 1 -- 4UP for 1st Correct Score
			WHEN betteam = '0:4' AND @goaldiff <=  -4 and @bettype=30 THEN 1 -- 4UP for 1st Correct Score
			WHEN betteam = '5:0' AND @goaldiff >=  5 THEN 1
			WHEN betteam = '0:5' AND @goaldiff <= -5 THEN 1
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
			WHEN @modds >  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,1204) then odds-1 else odds end) end)
			WHEN @modds =  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16,30,1204) then odds-1 else odds end) end) * 0.5
			WHEN @modds =  0	THEN actual_stake
			WHEN @modds = -0.25	THEN actual_stake * 0.5
			WHEN @modds < -0.25	THEN 0
			END,
					
		PlayerComm = CASE
			WHEN @modds >  0.25 	THEN @commWinRate * playerdiscount * dbo.[F_GetCommBase] (Stake,Odds,Bettype,@modds)
			WHEN @modds =  0.25 	THEN @commWinRate * playerdiscount * dbo.[F_GetCommBase] (Stake,Odds,Bettype,@modds)
			WHEN @modds =  0    	THEN 0
			WHEN @modds = -0.25 	THEN @commLostRate * playerdiscount * dbo.[F_GetCommBase] (Stake,Odds,Bettype,@modds)
			WHEN @modds < -0.25 	THEN @commLostRate * playerdiscount * dbo.[F_GetCommBase] (Stake,Odds,Bettype,@modds)
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
				WHEN @modds >  0.25 	THEN @commWinRate * Tdiscount * (1-[TPositionTaking]) * dbo.[F_GetCommBase] (Stake,Odds,Bettype,@modds)
				WHEN @modds =  0.25 	THEN @commWinRate * Tdiscount * (1-[TPositionTaking]) * dbo.[F_GetCommBase] (Stake,Odds,Bettype,@modds)
				WHEN @modds =  0    	THEN 0
				WHEN @modds = -0.25 	THEN @commLostRate * Tdiscount * (1-[TPositionTaking]) * dbo.[F_GetCommBase] (Stake,Odds,Bettype,@modds)
				WHEN @modds < -0.25 	THEN @commLostRate * Tdiscount * (1-[TPositionTaking]) * dbo.[F_GetCommBase] (Stake,Odds,Bettype,@modds)
				END
		 
	from 
		(	SELECT TransId, sum(AWinLost) aWinlost
			FROM @ba 
			GROUP BY TransId) AgentWinlost 
	WHERE
		AgentWinlost.TransID=BetTrans.TransId AND
		BetTrans.matchid=@matchid AND
		BetTrans.bettype=@bettype AND
		--[status] NOT IN (N'VOID', N'REJECT')
		BetTrans.statusID NOT IN (101,102)
	

	IF @FGLG2 IS NULL OR @FGLG2 = ''
		SET @FGLG2 = @correctscore

	-------------Start:Settle FGLG for bettransm-------------
	if @bettype = 14
	BEGIN
		SELECT @matchdate=eventdate FROM match WITH (NOLOCK) WHERE matchid=@matchid
																										UPDATE dbo.bettransm with (updlock)
		SET
			@modds =
				case 
					WHEN (betteam = @correctscore OR betteam = @FGLG2) THEN 1					
					ELSE -1
				END,
			ruben = CASE WHEN @modds IS NULL THEN 0 ELSE 1 END,
			winlostdate=@matchdate,
			[status]=
				case
					when @modds<0 then 'LOSE'
					when @modds>0 then 'WON'
				end ,
			statusID = 
				case
					when @modds<0 then 113 --LOSE
					when @modds>0 then 112 --WON
				end ,
			statuswinlost=
				case
					when @modds<=-0.5 then 4 -- LOSE
					when @modds>= 0.5 then 2 -- WIN
				end
		-- ========================
		FROM dbo.bettransm with (INDEX=IX_matchid)
		WHERE	bettype = @bettype 
				AND matchid = @matchid
				AND statusID NOT IN (101,102) --VOID, REJECT
				
		UPDATE dbo.betParlayDetail WITH(ROWLOCK,UPDLOCK)
		SET
			@modds =
				case 
					WHEN (betteam = @correctscore OR betteam = @FGLG2) THEN 1					
					ELSE -1
				END,
			winlostdate=@matchdate,
			statusID = 
				case
					when @modds<0 then 113 --LOSE
					when @modds>0 then 112 --WON
				end ,
			statuswinlost=
				case
					when @modds<=-0.5 then 4 -- LOSE
					when @modds>= 0.5 then 2 -- WIN
				end
		WHERE	bettype = @bettype 
				AND matchid = @matchid
				AND statusID NOT IN (101,102) --VOID, REJECT
				
	END 
	-------------Stop:Settle FGLG for bettransm-------------
END
GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_4] TO [aplweb]