ALTER PROCEDURE [dbo].[Acc_ExchangeUpd]
	@exchangeid int,
	@actualrate FLOAT,
	@minbet FLOAT = 0,
	@minbetlive FLOAT = 0,
	@Description Nvarchar(100) = '',
	@MultipliedBy int = 1,	
	@UserID INT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT,
	@IP VARCHAR(15) = ''
AS

/*
Created: 20130821@Sophia
Task : Update ex rate

DB: SVRTXN.TRANSDB
Original: 

Revisions: 
	 

Param's Explanation:
• @actualrate: new rate to update
• @minbet: update new minbet 


*/

SET NOCOUNT ON
 

declare 
	@LogData nvarchar(400),
	@old_minbet FLOAT ,
	@old_minbetlive FLOAT ,
	@old_actualrate FLOAT,
	@old_Description nvarchar(100),
	@old_MultipliedBy int


select 
	@old_minbet = minbet,
	@old_minbetlive = minbetlive,
	@old_actualrate = actualrate,	
	@old_Description = Description,
	@old_MultipliedBy = MultipliedBy	
from exchange with (nolock) where exchangeid=@exchangeid

UPDATE exchange SET 
	actualrate=@actualrate, 
	minbet=@minbet,
	minbetlive=@minbetlive,	
	Description = @Description,
	MultipliedBy = @MultipliedBy
WHERE exchangeid=@exchangeid


Select @LogData = 'Update exchange rate:'	
	+  ' ,newBaseRate=' + ISNULL(convert(VARCHAR(10), @actualrate),'')  
	+  ' ,oldBaseRate=' + ISNULL(convert(VARCHAR(10), @old_actualrate),'')  
	+  ' ,newminbet='+ ISNULL(convert(VARCHAR(10), @minbet),'') 
	+  ' ,oldminbet='+ ISNULL(convert(VARCHAR(10), @old_minbet),'') 
	+  ' ,newminbetlive='+ ISNULL(convert(VARCHAR(10), @minbetlive),'') 
	+  ' ,oldminbetlive='+ ISNULL(convert(VARCHAR(10), @old_minbetlive),'') 	
	+  ' ,oldDescription='+ ISNULL(@old_Description,'')
	+  ' ,newDescription='+ ISNULL(@Description,'')
	+  ' ,oldMultipliedBy='+ ISNULL(convert(varchar(10),@old_MultipliedBy),'')
	+  ' ,newMultipliedBy='+ ISNULL(convert(varchar(10),@MultipliedBy),'')	
	

EXEC SVRLOG.LogDB.dbo.WriteLog_ExchangeRate
	@UserID = @UserID, 
	@ExchangeID = @exchangeid, 
	@actualrate = @actualrate, 
	@IP = @IP, 
	@Doing = @LogData
GO

GRANT EXECUTE ON [dbo].[Acc_ExchangeUpd] TO [aplweb]
GO