ALTER PROCEDURE [dbo].[Age_Agent_ClearBalance]
	@AgentID INT ,
	@Username NVARCHAR(50),
	@Currency INT, 
	@CurrencyName VARCHAR(5),
	@ActualRate FLOAT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(1000) = '' OUTPUT
AS
/**
 * Created by	: Sophia
 * Date			: 20131201
 * Task			: Balance to 0 for Agent
 * DB			: SVRTXN.TransDB
 * Revisions	:
 *	•  
 * Parameters:
 *	•
 *	•
 *  
 */
DECLARE @refNo		BIGINT,
		@Now		Datetime,
		@Balance	MONEY,
		@TransID BIGINT 

		SELECT @Now = CURRENT_TIMESTAMP
			 	
		--Calculate Balance Of Agent		
		SELECT  @Balance = ISNULL(SUM(Amount) ,0)
		FROM
			(
			-- get winlost for direct child agent
			SELECT	SUM(BP.AWinlost + BP.AComm  - BA.AComm) as Amount						
			FROM BetTrans_Agent BP WITH (NOLOCK, index = CIX_MatchId_BetType) 		
			INNER JOIN AgentInfo A WITH (NOLOCK) ON A.ParentID = BP.AgentId
			INNER JOIN BetTrans_Agent BA WITH (NOLOCK, index = CIX_MatchId_BetType) ON A.AgentId = BA.AgentId AND BP.TransId = BA.TransId										
			WHERE	BP.AgentID = @AgentID
					AND BP.BETTYPE < 20000	
					AND BP.matchID >= 0 								
					AND BA.BETTYPE < 20000															
					AND BA.matchID >= 0 
			
			 UNION ALL						
			-- get winlost for direct member
			SELECT	SUM(BP.AWinlost + BP.AComm  - B.PlayerComm) as Amount
			FROM BetTrans_Agent BP  WITH (NOLOCK, index = CIX_MatchId_BetType)
			INNER JOIN bettrans B WITH (NOLOCK) ON B.TransId = BP.TransId	
			INNER JOIN CustInfo C WITH (NOLOCK) ON B.CustID = C.CustID AND C.AgentID = BP.AgentID 
			WHERE	BP.AgentID = @AgentID					
					AND BP.BETTYPE < 20000
					AND BP.matchID >= 0	
				
			 UNION ALL
			-- for balance record
			SELECT SUM(BP.AWinlost) as Amount
			FROM BetTrans_Agent BP  WITH (NOLOCK) 			
			WHERE	BP.AgentID = @AgentID		
					AND BP.bettype >= 20000  --BALANCE 		
					AND BP.matchID = 0
			) T
 
		
		IF @Balance <> 0
		BEGIN
			EXEC Acc_SelRefNo @RefNo = @RefNo OUTPUT
			SELECT @RefNo = @RefNo + 100000000000
		
		

		-- create a dummy record in bettrans so that we can link to bettrans_agent record
		INSERT INTO Bettrans 
					(Matchid, Creator, Custid, Username, Refno, Transdate, Bettype, Transdesc, Winlost, Actual_stake, PlayerComm, 
					Status,StatusID, Ruben, Winlostdate, Currency, VirtualRate, Actualrate, CurrencyName, TComm, TWinlost, IP)
			VALUES	(0, 8, 0, '', @refno, @Now, 22003, 'Delete agent account - Agent::'+@Username, 0, 0, 0,
					'Completed',131, 1, convert(nvarchar(10), @Now,120), @Currency, @Actualrate, @Actualrate, @CurrencyName, 0, 0,'')
			-- Check error
			IF @@ERROR > 0
			BEGIN
				SELECT 
					@ErrCode = 5117, 
					@ErrMsg = 'Failed to clear balance of agent [AgentID = ' + COALESCE(CAST(@AgentID AS VARCHAR(10)), SPACE(1)) + ']'						 
				RETURN
			END	
			ELSE 
			SELECT @TransID = SCOPE_IDENTITY() 


		---- Insert balance record into bettrans_agent
		
		SELECT @Balance = -@Balance

		INSERT INTO Bettrans_Agent 
					(TransId, AgentId,TransDate, Stake, Actual_Stake, Status, AWinLost, AComm, APositionTaking, ADiscount, 
					RefNo, WinLostDate, ActualRate, MatchId, BetType, Currency, IP, TransDesc, Username, CurrencyName, 
					VirtualRate, StatusId, SecAcceptFlag)
		VALUES		(@TransId, @AgentId, @Now, 0, 0, 'Completed', @Balance, 0, 0, 0,
					@RefNo, convert(nvarchar(10), @Now,120), @ActualRate,0, 22003, @Currency, 0,'Delete agent account - Agent::'+@Username, @Username, @CurrencyName,
					@ActualRate, 131, 0)
			-- Check error
			IF @@ERROR > 0
			BEGIN
				DELETE Bettrans WHERE TransID= @TransID

				SELECT 					
					@ErrCode = 5118, 
					@ErrMsg = 'Failed to clear balance of agent [AgentID = ' + COALESCE(CAST(@AgentID AS VARCHAR(10)), SPACE(1)) + ']'						 
				RETURN
			END	
		
	END
GO