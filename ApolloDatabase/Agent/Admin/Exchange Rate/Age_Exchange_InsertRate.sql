ALTER PROCEDURE [dbo].[Age_Exchange_InsertRate]
    @ExchangeId			INT							OUTPUT,
	@Currency			NVARCHAR(50),	
	@Description		VARCHAR(100)	= NULL,	
	@MultipliedBy		FLOAT,
	@BaseRate			FLOAT,
	@MinBet				FLOAT,
	@MinBetLive			FLOAT,

    @CurrentUserId		INT,
	@LogDate			DATETIME,
	@LoginIP			VARCHAR(30)		= '',
	@Language			VARCHAR(20)		= 'en-us',

	@ErrCode			INT				= 0			OUTPUT, 
	@ErrMsg				NVARCHAR(1000)	= ''		OUTPUT 
AS

/*  
 * Created: 20130320@Lewis
 * Task : Insert exchange rate
 * DB: [ProdDB]
 *  
 * Revisions:
 * Param's Explanation:
*/

BEGIN

	SET NOCOUNT ON
	
	-- for writing log
	--DECLARE 
	--	@startRun		DATETIME,
	--	@endRun			DATETIME,
	--	@duration		INT,
	--	@logSPData		VARCHAR(5000),
	--	@xml			XML	

	--SET @startRun = GETDATE()

	-- insert exchange rate
	INSERT [dbo].[Exchange]
	(
		[Currency],
		[Description],
		[MultipliedBy],
		[actualrate],
		[MinBet],
		[MinBetLive],
		[Creator]
	)
	VALUES
	(
		@Currency,
		@Description,
		@MultipliedBy,
		@BaseRate,
		@MinBet,
		@MinBetLive,
		''
	)

	SET @ExchangeId = SCOPE_IDENTITY()
	
	SELECT @ErrCode = @@ERROR
	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrMsg = 'Failed to insert exchange rate'
		RETURN
	END

	-- write log after update
	--SET @xml = ''
	--SET @logSPData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')
		
	--SET @endRun		= GETDATE()  
	--SET @duration	= DATEDIFF(millisecond, @startRun, @endRun)   

	--EXEC LOGGING
END