ALTER  PROCEDURE [dbo].[Task_MoveCustArchive]
	@Date Date = NULL
AS 
BEGIN 
	IF @Date IS NULL SET @Date = GETDATE()

--1.AgentUserFunction
	INSERT INTO SVRCUSTARC.CustArchiveDB.dbo.AgentUserFunction (
			AgentUserId,
			FunctionId,
			AgentId,
			Policy,
			ArchiveDate
		)
	SELECT 
		AgentUserId, 
		FunctionId,
		AgentId,
		Policy,
		ArchiveDate
	FROM AgentUserFunction WITH (NOLOCK)
	WHERE ArchiveDate < CONVERT(DATE,@Date)
	
	-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when archiving AgentUserFunction.', 16, 1)
			RETURN 
		END


	DELETE AgentUserFunction WHERE ArchiveDate < CONVERT(DATE,@Date)	 
	-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when deleting AgentUserFunction.', 16, 1)
			RETURN
		END

--2.AgentBetLimit
	INSERT INTO SVRCUSTARC.CustArchiveDB.dbo.AgentBetLimit (
		AgentId,
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch,
		ArchiveDate)
	SELECT 	
		AgentId,
		SportType,
		BetType,
		MinBet,			
		MaxBet,			
		MaxPerMatch,
		ArchiveDate
	FROM AgentBetLimit WITH (NOLOCK)
	WHERE ArchiveDate <  CONVERT( DATE, @Date)
		-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when archiving AgentBetLimit.', 16, 1)
			RETURN 
		END

DELETE AgentBetLimit WHERE ArchiveDate <  CONVERT( DATE, @Date) 
	-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when deleting AgentBetLimit.', 16, 1)
			RETURN 
		END

--3. AgentDiscount
INSERT INTO SVRCUSTARC.CustArchiveDB.dbo.AgentDiscount (
		AgentId,
		SportType,
		BetType,
		DiscountA,
		DiscountB,
		DiscountC,
		DiscountD,
		ArchiveDate)
	SELECT 
		AgentId,
		SportType,
		BetType,
		DiscountA,		
		DiscountB,		
		DiscountC,		
		DiscountD,
		ArchiveDate
	FROM AgentDiscount WITH (NOLOCK)
	WHERE ArchiveDate < CONVERT( DATE, @Date)
		-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when archiving AgentDiscount.', 16, 1)
			RETURN 
		END

DELETE AgentDiscount WHERE ArchiveDate <  CONVERT( DATE, @Date) 
	-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when deleting AgentDiscount.', 16, 1)
			RETURN 
		END

--4.AgentPositionTaking
INSERT INTO SVRCUSTARC.CustArchiveDB.dbo.AgentPositionTaking (
		AgentId,
		SportType,
		BetType,
		IsLive,
		MaxUpperPositionTaking,
		MaxGivenPositionTaking,
		MinGivenPositionTaking,
		ArchiveDate)
	SELECT 
		AgentId,
		SportType,
		BetType,
		IsLive,
		MaxUpperPositionTaking,
		MaxGivenPositionTaking,
		MinGivenPositionTaking,
		ArchiveDate
	FROM AgentPositionTaking WITH (NOLOCK)	
	WHERE ArchiveDate < CONVERT( DATE, @Date) 
		-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when archiving AgentPositionTaking.', 16, 1)
			RETURN 
		END

DELETE AgentPositionTaking WHERE ArchiveDate <  CONVERT( DATE, @Date) 
	-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when deleting AgentPositionTaking.', 16, 1)
			RETURN 
		END

--5.AgentCustPositionTaking
INSERT INTO SVRCUSTARC.CustArchiveDB.dbo.AgentCustPositionTaking (
		AgentCustId,
		AgentId,
		SportType,
		BetType,
		IsLive,
		PositionTaking,
		ArchiveDate)
	SELECT 
		AgentCustId,
		AgentId,
		SportType,
		BetType,
		IsLive,
		PositionTaking,
		ArchiveDate
	FROM AgentCustPositionTaking WITH (NOLOCK)
	WHERE ArchiveDate < CONVERT( DATE, @Date) 
		-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when archiving AgentCustPositionTaking.', 16, 1)
			RETURN 
		END


DELETE AgentCustPositionTaking WHERE ArchiveDate <  CONVERT( DATE, @Date) 
	-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when deleting AgentCustPositionTaking.', 16, 1)
			RETURN 
		END

--6.AgentUser
INSERT INTO SVRCUSTARC.CustArchiveDB.dbo.AgentUser (
		AgentUserId,
		AgentId,
		Username,
		IsMaster,
		PageAccess,
		CreateDate,
		Creator,
		LoginCount,
		Status,
		ArchiveDate
	)
	SELECT 
		AgentUserId,
		AgentId,
		Username,
		IsMaster,
		PageAccess,
		CreateDate,
		Creator,
		LoginCount,
		Status,
		ArchiveDate
	FROM AgentUser WITH (NOLOCK)
	WHERE ArchiveDate < CONVERT( DATE, @Date) 
		-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when archiving AgentUser.', 16, 1)
			RETURN 
		END


DELETE AgentUser WHERE ArchiveDate <  CONVERT( DATE, @Date) 
	-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when deleting AgentUser.', 16, 1)
			RETURN 
		END

---7.AgentInfo
INSERT INTO SVRCUSTARC.CustArchiveDB.dbo.AgentInfo (
		AgentId,
		AgentHId,
		AgentLevel,
		Username,
		Currency,
		ParentId,
		AutoSuspend,
		MatchLimit,
		VirtualMultiplier,
		DoubleCommLosing,
		Status,
		BetStatus,
		UplineStatus,
		UplineBetStatus,
		ArchiveDate
	)
	SELECT 
		AgentId,
		AgentHId,
		AgentLevel,
		Username,
		Currency,
		ParentId,
		AutoSuspend,
		MatchLimit,
		VirtualMultiplier,
		DoubleCommLosing,
		Status,
		BetStatus,
		UplineStatus,
		UplineBetStatus,
		ArchiveDate
	FROM AgentInfo WITH (NOLOCK)	
	WHERE ArchiveDate < CONVERT( DATE, @Date) 
		-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when archiving AgentInfo.', 16, 1)
			RETURN 
		END


DELETE AgentInfo WHERE ArchiveDate <  CONVERT( DATE, @Date) 
	-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when deleting AgentInfo.', 16, 1)
			RETURN 
		END

---8.CustBetLimit
INSERT INTO SVRCUSTARC.CustArchiveDB.dbo.CustBetLimit (
		CustId,
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch,
		ArchiveDate)
	SELECT 	
		CustId,
		SportType,
		BetType,
		MinBet,			
		MaxBet,			
		MaxPerMatch,
		ArchiveDate
	FROM CustBetLimit WITH (NOLOCK)
	WHERE ArchiveDate <  CONVERT( DATE, @Date) 
		-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when archiving CustBetLimit.', 16, 1)
			RETURN 
		END

DELETE CustBetLimit  WHERE ArchiveDate <  CONVERT( DATE, @Date) 
	-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when deleting CustBetLimit.', 16, 1)
			RETURN 
		END

---9.CustDiscount
INSERT INTO SVRCUSTARC.CustArchiveDB.dbo.CustDiscount (
		CustId,
		SportType,
		BetType,
		Discount,
		ArchiveDate)
	SELECT 
		CustId,
		SportType,
		BetType,
		Discount,
		ArchiveDate
	FROM CustDiscount WITH (NOLOCK)
	WHERE ArchiveDate <  CONVERT( DATE, @Date) 
		-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when archiving CustDiscount.', 16, 1)
			RETURN 
		END

DELETE CustDiscount WHERE ArchiveDate <  CONVERT( DATE, @Date) 
	-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when deleting CustDiscount.', 16, 1)
			RETURN 
		END

--10.CustInfo
INSERT INTO SVRCUSTARC.CustArchiveDB.dbo.CustInfo (
		CustId,
		AgentId,
		Username,
		Currency,
		AutoSuspend,
		MatchLimit,
		VirtualMultiplier,
		Danger,
		Creator,
		CreateDate,
		LastLogged,
		IPLogin,
		UGroup,
		DoubleCommLosing,
		Status,
		BetStatus,
		UplineStatus,
		UplineBetStatus,
		IsUGroupChanged,
		ArchiveDate
	)
	SELECT 
		CustId,
		AgentId,
		Username,
		Currency,
		AutoSuspend,
		MatchLimit,
		VirtualMultiplier,
		Danger,
		Creator,
		CreateDate,
		LastLogged,
		IPLogin,
		UGroup,
		DoubleCommLosing,
		Status,
		BetStatus,
		UplineStatus,
		UplineBetStatus,
		IsUGroupChanged,
		ArchiveDate
	FROM CustInfo WITH (NOLOCK)
	WHERE ArchiveDate <  CONVERT( DATE, @Date) 
		-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when archiving CustInfo.', 16, 1)
			RETURN 
		END

DELETE CustInfo WHERE ArchiveDate <  CONVERT( DATE, @Date) 
	-- Check error
		IF @@ERROR > 0
		BEGIN 
			RAISERROR ('Error when deleting CustInfo.', 16, 1)
			RETURN 
		END



END

