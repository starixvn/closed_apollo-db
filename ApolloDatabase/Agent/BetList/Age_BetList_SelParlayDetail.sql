ALTER PROCEDURE [dbo].[Age_BetList_SelParlayDetail]
	@TransID	bigint,
	@Language	varchar(2) = 'E'
 AS
/*
Created: 20130422@Sophia
Task : get parlay tickets
DB: SVRAGE.REPDB
Original: 

Revisions:    

*/
SET NOCOUNT ON
DECLARE	@tmpParlay	TABLE(
	transid		BIGINT,
	sporttype	INT,
	leagueid	INT,
	bettype		INT,
	homeid		INT,
	awayid		INT,
	hdp1		FLOAT,
	hdp2		FLOAT,
	odds		SMALLMONEY,
	betteam		NVARCHAR(50),
	statusid	INT,
	livehomescore	SMALLINT,
	liveawayscore	SMALLINT,
	liveindicator	BIT,
	betstatus	NVARCHAR(50),
	isNeutral	BIT
)	

Declare @refno bigint, @custID int

SELECT @refno = refno, @custID = custid from bettrans with (NOLOCK) where TransID = @TransID
IF @refno IS NULL 	
BEGIN
	SELECT @refno = refno, @custID = custid from bettrans14 with (NOLOCK) where TransID = @TransID
	IF @refno IS NULL 
	BEGIN
		SELECT @refno = refno, @custID = custid from SVRARC.ArchiveDB.dbo.bettrans_BK with (NOLOCK) where TransID = @TransID
	END
END
IF EXISTS (SELECT 1 FROM bettransm WITH (NOLOCK) WHERE refno = @refno and custid = @custid)
BEGIN
	INSERT INTO @tmpParlay (
		transid,
		sporttype,
		leagueid,
		bettype,
		homeid,
		awayid,
		hdp1,
		hdp2,
		odds,
		betteam,
		statusid,
		livehomescore,
		liveawayscore,
		liveindicator,
		betstatus,
		isNeutral
	)
	SELECT
		b.transid,
		m.Sporttype,
		m.LeagueID,		
		b.Bettype ,
		m.homeID,
		m.awayID,
		convert(float, b.hdp1) as Hdp1, 
		convert(float, b.hdp2) as Hdp2, 
		b.odds,
		b.Betteam,
		b.statusid,
		b.livehomescore,
		b.liveawayscore,
		b.liveindicator,
		m.betstatus,
		m.isNeutral
	FROM(	SELECT 
					transid,
					matchid,  
					Bettype, 
					hdp1, 
					hdp2, 
					odds, 
					betteam, 
					statusid,
					livehomescore,
					liveawayscore,
					liveindicator
			FROM	BettransM with (nolock)
					WHERE refno=@refno and custID = @custID              
		) AS b		
			inner join match as m with (nolock) on b.matchid=m.matchid
END
IF EXISTS (SELECT 1 FROM bettransm14 WITH (NOLOCK) WHERE refno = @refno and custid = @custid)
BEGIN
	INSERT INTO @tmpParlay (
		transid,
		sporttype,
		leagueid,
		bettype,
		homeid,
		awayid,
		hdp1,
		hdp2,
		odds,
		betteam,
		statusid,
		livehomescore,
		liveawayscore,
		liveindicator,
		betstatus,
		isNeutral
	)
	SELECT
		b.transid,
		m.Sporttype,
		m.LeagueID,		
		b.Bettype ,
		m.homeID,
		m.awayID,
		convert(float, b.hdp1) as Hdp1, 
		convert(float, b.hdp2) as Hdp2, 
		b.odds,
		b.Betteam,
		b.statusid,
		b.livehomescore,
		b.liveawayscore,
		b.liveindicator,
		m.betstatus,
		m.isNeutral
	FROM(	SELECT 
					transid,
					matchid,  
					Bettype, 
					hdp1, 
					hdp2, 
					odds, 
					betteam, 
					statusid,
					livehomescore,
					liveawayscore,
					liveindicator
			FROM	BettransM14 with (nolock)
					WHERE refno=@refno and custID = @custID              
		) AS b		
			inner join match14 as m with (nolock) on b.matchid=m.matchid
END
IF EXISTS (SELECT 1 FROM SVRARC.ArchiveDB.dbo.BettransM WITH (NOLOCK) WHERE refno = @refno)
BEGIN
	INSERT INTO @tmpParlay (
		transid,
		sporttype,
		leagueid,
		bettype,
		homeid,
		awayid,
		hdp1,
		hdp2,
		odds,
		betteam,
		statusid,
		livehomescore,
		liveawayscore,
		liveindicator,
		betstatus,
		isNeutral
	)
	SELECT
		b.transid,
		m.Sporttype,
		m.LeagueID,		
		b.Bettype ,
		m.homeID,
		m.awayID,
		convert(float, b.hdp1) as Hdp1, 
		convert(float, b.hdp2) as Hdp2, 
		b.odds,
		b.Betteam,
		b.statusid,
		b.livehomescore,
		b.liveawayscore,
		b.liveindicator,
		m.betstatus,
		m.isNeutral
	FROM(	SELECT 
					transid,
					matchid,  
					Bettype, 
					hdp1, 
					hdp2, 
					odds, 
					betteam, 
					statusid,
					livehomescore,
					liveawayscore,
					liveindicator
			FROM	SVRARC.ArchiveDB.dbo.BettransM with (nolock)
					WHERE refno=@refno  and custID = @custID          
		) AS b		
			inner join SVRARC.ArchiveDB.dbo.match_bk as m with (nolock) on b.matchid=m.matchid	
END
SELECT * FROM @tmpParlay
ORDER BY transID DESC 



GO
GRANT EXECUTE ON [dbo].[Age_BetList_SelParlayDetail] TO [aplweb]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_BetList_SelParlayDetail] TO [vnteam]
