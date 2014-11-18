USE [master]
GO
/****** Object:  StoredProcedure [dbo].[DBA_GetSQLErrorLogEvents]    Script Date: 07/17/2013 03:59:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[DBA_GetSQLErrorLogEvents] 
(@LogNumber int = 0 , @runlocal int =  0 , @NumberOfMinutes int = 5 )

AS
/*
--  Test Variables -------
declare @Lognumber smallint
declare @runlocal bit
declare @NumberOfMinutes int
set @Lognumber = 0
set @runlocal = 0
set @NumberOfMinutes=5
-------------------------
*/


declare @count  smallint ,
        @SQL    varchar (1000 ),
        @output varchar (255 ),
        @runtime datetime ,
        @sqlversion varchar (10 )
 
set @count  = 0
set @SQL    = ''
set @output = ''
set @sqlversion = rtrim( ltrim( substring ( @@version , 22 , 5 )))
set @runtime = getdate()
 
if @runlocal = 1
       set @runtime = getdate()- 100

if object_id ('tempdb..#errors' ) is not null
begin
   drop table #errors
end
 
CREATE TABLE #errors
(
      RowID int IDENTITY PRIMARY KEY ,
      EntryTime datetime ,
       source varchar ( 50),
      LogEntry varchar (4000 )
)
 
select @SQL = 'exec master..xp_readerrorlog ' + convert ( varchar ( 3 ), @lognumber)
insert into #errors ( entrytime , source, logentry)
execute (@SQL )

delete #errors
where (logentry not like '%err%'
             AND logentry not like '%warn%'
             AND logentry not like '%kill%'
             AND logentry not like '%dead%'
             AND logentry not like '%cannot%'
             AND logentry not like '%could%'
             AND logentry not like '%fail%'
             AND logentry not like '%not%'
             AND logentry not like '%stop%'
             AND logentry not like '%terminate%'
             AND logentry not like '%bypass%'
             AND logentry not like '%roll%'
             AND logentry not like '%truncate%'
             AND logentry not like '%upgrade%'
             AND logentry not like '%victim%'
             AND logentry not like '%recover%'
             AND logentry not like '%IO requests taking longer than%' )
             OR logentry like '%errorlog%'
             OR logentry like '%dbcc%'
             OR LogEntry like '%This is an informational message only%'

DELETE #Errors
WHERE EntryTime IS NULL OR EntryTime <    dateadd( mi , (- 1* @NumberOfMinutes), @runtime )
 
-- If local only return the events table back to the Results Grid
IF @RunLocal = 1
BEGIN
       SELECT *
       FROM #errors
END
ELSE -- Insert the errors into the SystemEvents table to trigger notification.
BEGIN
 
       CREATE TABLE #Exceptions
       (
            RowID int identity Primary Key ,
            LogEntry varchar (4000 ),
            EntryCount int ,
            LastOccurence datetime
       )
 
       INSERT INTO #Exceptions ( LogEntry , EntryCount , LastOccurence)
       SELECT LogEntry, count(*), max( EntryTime )
       FROM #Errors
       GROUP BY LogEntry
 
       DECLARE @Loop2 int
       DECLARE @SubjectStr varchar ( 100)
       DECLARE @strMsg varchar ( 4000)

       SELECT @SubjectStr = 'SQL Monitor Alert: ' + @@servername

       SELECT @Loop2 = min( RowID )
       FROM #Exceptions

       WHILE @Loop2 IS NOT NULL
       BEGIN

             SELECT       @strMsg =  convert (char ( 15), 'LogEntry:') + isnull (LogEntry , 'Unknown' ) + char ( 10) +
                         convert (char ( 15), 'EventTime:') + convert (varchar , LastOccurence ) + char( 10 ) +
                         convert (char ( 15), '') + char (10 ) +
                         convert (char ( 15), '') + 'This error has occured '+ convert(   varchar, EntryCount )+' times.'
             FROM #Exceptions
             WHERE RowID = @Loop2

             ---------------------------------------
             EXEC msdb. dbo .sp_send_dbmail
                  @recipients = 'dan.nguyen@nexcel.vn',--'vincent.cheng@onelab.tw;vivi.kao@onelab.tw' ,
                  @subject = @SubjectStr,
                  @body = @strMsg
             ---------------------------------------
             SELECT @Loop2 = min( RowID )
             FROM #Exceptions
             WHERE RowID > @Loop2

       END
 
END
 
DROP TABLE #Exceptions
DROP TABLE #Errors
