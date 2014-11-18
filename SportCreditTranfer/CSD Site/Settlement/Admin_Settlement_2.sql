ALTER PROCEDURE [dbo].[Admin_Settlement_2]
	@betstatus nvarchar(50),
	@Total smallint OUTPUT,
	@TotalHome smallint OUTPUT,
	@TotalAway smallint OUTPUT
AS
-- check for Tennis total game played.
-- for calculate of Over/Under, Odd/Even

Declare @EachSet TABLE (Score nvarchar(10))
INSERT INTO @EachSet SELECT val FROM dbo.StrSplit(@betstatus, ',')

Declare @tbScore TABLE ([Set] tinyint IDENTITY(1,1), H smallint, A smallint)
Declare @TMP TABLE ([id] tinyint, score tinyint)
Declare s_cur CURSOR FOR Select Score FROM @EachSet
Declare @Score nvarchar(10), @H smallint, @A smallint

OPEN s_cur
FETCH NEXT FROM s_cur INTO @Score
WHILE @@FETCH_STATUS = 0
BEGIN
	DELETE FROM @TMP
	INSERT INTO @TMP ([id], score) SELECT [id], val FROM dbo.StrSplit(@Score, '-')
	SELECT TOP 1 @H = score FROM @TMP ORDER BY [id]
	SELECT TOP 1 @A = score FROM @TMP ORDER BY [id] DESC
	INSERT INTO @tbScore (H, A) VALUES (@H, @A)

	FETCH NEXT FROM s_cur INTO @Score
END
CLOSE s_cur
DEALLOCATE s_cur

SELECT @Total = SUM(H+A), @TotalHome = SUM(H), @TotalAway = SUM(A) FROM @tbScore



GO
