ALTEr PROCEDURE [dbo].[Acc_SpecialDel_CheckMatchIdWithRefNo]
	@MatchId int,
	@FromRefNo bigint, --transid
	@ToRefNo bigint, --transid
	@Type SMALLINT = 0,
	@ErrMsg NVARCHAR(200) = '' OUTPUT,
    @ErrCode INT = 0 OUTPUT
AS
BEGIN
/*
	Created by: Sophia
	Date:  20130305
	Task: check constraint between refno and matchid
	DB: ApolloArchive.TransDB	
	Original: 
	
	Revisions:
			
	Param's Explanation:	
		- @Type: sports type
			0: Sportsbook
			1: Number Game
			2: Parlay
		
*/
	SET NOCOUNT ON
	DECLARE @totalRecord INT, @Sporttype int
		
	SELECT @Sporttype = sporttype
	FROM  match with (NOLOCK)
	WHERE matchid = @MatchID

	IF  (@Sporttype IS NULL)
	BEGIN 
			SET @ErrCode = 1
			SET @ErrMsg ='This MatchId is invalid.' 
			RETURN
	END
	
	IF @Type IN (0,1) 
	BEGIN
		IF (@Sporttype not between 1 and 99 AND @Type = 0 ) OR (@Sporttype IS NULL)
		BEGIN 
			SET @ErrCode = 2
			SET @ErrMsg ='This MatchId doesn''t belong to sportbook.' 
			RETURN
		END 
		ELSE
		IF (@Sporttype <> 161 AND @Type = 1 ) OR (@Sporttype IS NULL)
		BEGIN 
			SET @ErrCode =3
			SET @ErrMsg ='This MatchId doesn''t belong to number game.' 
			RETURN
		END 
	
	END
	ELSE
	IF @Type = 2
	BEGIN	
		IF (@Sporttype =161) OR (@Sporttype IS NULL)
			SET @ErrCode = 4
			SET @ErrMsg ='This MatchId is invalid.' 
			RETURN
	END
	

	IF NOT EXISTS (SELECT TOP 1 1 
					FROM dbo.bettrans WITH (NOLOCK)		
					WHERE transid = @FromRefno
						AND matchid = @MatchID)
	BEGIN 
		SET @ErrCode =5
		SET @ErrMsg ='You have entered an invalid From BetId.' 
		RETURN
	END
		
	IF NOT EXISTS (SELECT TOP 1 1 
					FROM dbo.bettrans WITH (NOLOCK)		
					WHERE transid = @ToRefno
						AND matchid = @MatchID)
	BEGIN 
		SET @ErrCode =6
		SET @ErrMsg ='You have entered an invalid To BetId.' 
		RETURN
	END
	
	SET NOCOUNT OFF
END



GO
GRANT EXECUTE ON [dbo].[Acc_SpecialDel_CheckMatchIdWithRefNo] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[[Acc_SpecialDel_CheckMatchIdWithRefNo]] TO [vnteam] AS [dbo]
  
 

 



