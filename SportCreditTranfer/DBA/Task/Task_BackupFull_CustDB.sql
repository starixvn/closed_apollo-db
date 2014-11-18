
/****** Object:  StoredProcedure [dbo].[Task_BackupFull_CustDB]    Script Date: 05/21/2013 02:21:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_BackupFull_CustDB]
	@suffix varchar(20) = ''
AS

--DBCC SHRINKFILE (N'CustDB_Log')
--BACKUP

Declare @Date nvarchar(50)
Declare @Time nvarchar(50)
Set @Date = 
CAST(DATEPART(year, CURRENT_TIMESTAMP) as nvarchar) + 
CASE WHEN DATEPART(month, CURRENT_TIMESTAMP) < 10 THEN '0' + CAST(DATEPART(month, CURRENT_TIMESTAMP) as nvarchar) ELSE CAST(DATEPART(month, CURRENT_TIMESTAMP) as nvarchar) END + 
CASE WHEN DATEPART(day, CURRENT_TIMESTAMP)   < 10 THEN '0' + CAST(DATEPART(day, CURRENT_TIMESTAMP) as nvarchar)   ELSE CAST(DATEPART(day, CURRENT_TIMESTAMP) as nvarchar) END
Set @Time = 
CASE WHEN DATEPART(hour, CURRENT_TIMESTAMP)  < 10 THEN '0' + CAST(DATEPART(hour, CURRENT_TIMESTAMP) as nvarchar)  ELSE CAST(DATEPART(hour, CURRENT_TIMESTAMP) as nvarchar) END +
CASE WHEN DATEPART(minute,CURRENT_TIMESTAMP) < 10 THEN '0' + CAST(DATEPART(minute,CURRENT_TIMESTAMP) as nvarchar) ELSE CAST(DATEPART(minute,CURRENT_TIMESTAMP) as nvarchar) END

Declare @Backup_File nvarchar(200)
Set @Backup_File = 'D:\APL_DB\BACKUP\CustDB_backup_' + @Date + '_' + @Time + 
	CASE @suffix WHEN '' THEN 'DF' ELSE @suffix END + '.bak'
Declare @Desc nvarchar(255) Set @Desc = 'Full Backup for ' + @Date
Declare @Name nvarchar(128) Set @Name = @Date + ' ' + @Time + CASE @suffix WHEN '' THEN ' DIFF_BK' ELSE ' FULL_BK' END

IF @suffix = ''
	BACKUP DATABASE CustDB TO DISK = @Backup_File
	WITH DIFFERENTIAL,COMPRESSION,
	 DESCRIPTION = @Desc, NOFORMAT, NOINIT
	,NAME = @Name
	,SKIP, NOREWIND, NOUNLOAD
	,CHECKSUM
ELSE
	BACKUP DATABASE CustDB TO DISK = @Backup_File 
	WITH COMPRESSION,
	 DESCRIPTION = @Desc
	,NAME = @Name
	,CHECKSUM


	 