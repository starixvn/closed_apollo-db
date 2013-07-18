USE [master]
GO
/****** Object:  StoredProcedure [dbo].[TASK_CheckFreeSpace]    Script Date: 07/17/2013 04:39:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[TASK_CheckFreeSpace]
AS
BEGIN
	DECLARE @MB_Free INT 
	CREATE TABLE #FreeSpace(Drive CHAR(1), MB_Free INT) 

	INSERT INTO #FreeSpace EXEC xp_fixeddrives 
	SELECT @MB_Free = MB_Free FROM #FreeSpace WHERE Drive = 'C' 

	-- Free Space on C drive Less than Threshold 
	IF (@MB_Free < 3072)
	BEGIN
		PRINT @MB_Free
		RAISERROR('C: OS and system database partition free space is now lower than 3GB ',16,1)
	END
	
	SELECT @MB_Free = MB_Free FROM #FreeSpace WHERE Drive = 'D' 
	-- Free Space on D drive Less than Threshold 
	IF (@MB_Free < 20480)
	BEGIN
		PRINT @MB_Free
		RAISERROR('D: Data partition free space is now lower than 20GB ',16,1)
	END

	SELECT @MB_Free = MB_Free FROM #FreeSpace WHERE Drive = 'G' 
	-- Free Space on G drive Less than Threshold 
	IF (@MB_Free < 20480)
	BEGIN
		PRINT @MB_Free
		RAISERROR('G: Data partition free space is now lower than 20GB ',16,1)
	END
	
	SELECT @MB_Free = MB_Free FROM #FreeSpace WHERE Drive = 'H' 
	-- (RS) Free Space on H drive Less than Threshold 
	IF (@MB_Free < 20480)
	BEGIN
		PRINT @MB_Free
		RAISERROR('H: User Databasae Data partition free space is now lower than 20GB ',16,1)
	END
	/*
	SELECT @MB_Free = MB_Free FROM #FreeSpace WHERE Drive = 'I' 
	-- (RS) Free Space on I drive Less than Threshold 
	IF (@MB_Free < 10240)
	BEGIN
		PRINT @MB_Free
		RAISERROR('I-RS: MSDTC Data partition free space is now lower than 10GB',16,1)
	END

	DROP TABLE #FreeSpace 
	*/
END


