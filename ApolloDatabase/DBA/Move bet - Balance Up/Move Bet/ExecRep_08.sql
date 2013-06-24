 
/****** Object:  StoredProcedure [dbo].[ExecRep_08]    Script Date: 05/07/2013 02:43:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ExecRep_08]
	@CustIDs varchar(max) = '',
	@IsAgent BIT = NULL,
	@Winlostdate smalldatetime,
	@Parlay bit = 0
AS
/*
Created by: Sophia
Date: 20130521
Task: Copy bettrans/bettransm -> bettrans14/bettransm14 for whole day of @winlostdate
DB: SVRTXN.TransDB

Revisions:
     
    
 */
SET NOCOUNT ON

IF @parlay = 1
	BEGIN


		INSERT INTO bettransm14
			(TransId,CustId,TransDate,OddsId,Hdp1,Hdp2,Odds,Stake,Status,WinLost,LiveHomeScore,LiveAwayScore,LiveIndicator,
			BetTeam,Creator,RefNo,ComStatus,WinLostDate,BetFrom,BetCheck,CheckTime,OddsSpread,PlayerDiscount,PlayerComm,
			ActualRate,MatchId,MatchDate,FinalOdds,IsFinish,StatusWinLost,Ruben,Bettype,StatusId,RecommDate
			)
		SELECT
			TransId,CustId,TransDate,OddsId,Hdp1,Hdp2,Odds,Stake,Status,WinLost,LiveHomeScore,LiveAwayScore,LiveIndicator,
			BetTeam,Creator,RefNo,ComStatus,WinLostDate,BetFrom,BetCheck,CheckTime,OddsSpread,PlayerDiscount,PlayerComm,
			ActualRate,MatchId,MatchDate,FinalOdds,IsFinish,StatusWinLost,Ruben,Bettype,StatusId,RecommDate
		FROM bettransm b WITH (NOLOCK)			 
		WHERE winlostdate=@winlostdate
			 
	END
ELSE
	BEGIN 
	IF @IsAgent = 0
		BEGIN
			INSERT INTO bettrans14 
				(TransId,CustId,TransDate,OddsId,Hdp1,Hdp2,Odds,Stake,Status,WinLost,PlayerComm,PlayerDiscount,
				TWinLost,TComm,TPositionTaking,TDiscount,AgentIdList,AgentPositionTakingList,AgentDiscountList,
				LiveHomeScore,LiveAwayScore,LiveIndicator,BetTeam,Creator,RefNo,WinLostDate,BetFrom,BetCheck,
				CheckTime,OddsSpread,ActualRate,MatchId,Ruben,BetId,StatusWinLost,MOdds,BetType,Actual_Stake,
				Currency,IP,TransDesc,Username,CurrencyName,VirtualRate,StatusId,DoubleCommLosing,SecAcceptFlag,OddsType,balance
				)
			SELECT 
				TransId,CustId,TransDate,OddsId,Hdp1,Hdp2,Odds,Stake,Status,WinLost,PlayerComm,PlayerDiscount,
				TWinLost,TComm,TPositionTaking,TDiscount,AgentIdList,AgentPositionTakingList,AgentDiscountList,
				LiveHomeScore,LiveAwayScore,LiveIndicator,BetTeam,Creator,RefNo,WinLostDate,BetFrom,BetCheck,
				CheckTime,OddsSpread,ActualRate,MatchId,Ruben,BetId,StatusWinLost,MOdds,BetType,Actual_Stake,
				Currency,IP,TransDesc,Username,CurrencyName,VirtualRate,StatusId,DoubleCommLosing,SecAcceptFlag,OddsType,balance
			FROM bettrans WITH (NOLOCK)
			WHERE CustId IN (select val FROM StrSplit_key(@CustIds,','))
				AND winlostdate=@winlostdate
				AND bettype <= 19000
		END
	 ELSE
		BEGIN 
			INSERT INTO bettrans14_Agent 
			(TransId,AgentId,TransDate,Stake,Actual_Stake,Status,AWinLost,AComm,APositionTaking,ADiscount,RefNo,WinLostDate,
			ActualRate,MatchId,BetType,Currency,IP,TransDesc,Username,CurrencyName,VirtualRate,StatusId,SecAcceptFlag
			)
			SELECT TransId,AgentId,TransDate,Stake,Actual_Stake,Status,AWinLost,AComm,APositionTaking,ADiscount,RefNo,WinLostDate,
			ActualRate,MatchId,BetType,Currency,IP,TransDesc,Username,CurrencyName,VirtualRate,StatusId,SecAcceptFlag
			FROM bettrans_Agent WITH (NOLOCK)
			WHERE AgentId IN (select val FROM StrSplit_key(@CustIds,',')) 
				AND winlostdate=@winlostdate
				AND bettype <= 19000 
		END
	END