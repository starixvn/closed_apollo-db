ALTER PROCEDURE [dbo].[WriteLog_Settlement_SettleOutright]
	@UserID int, 
	@OrId int, 
	@LeagueId int, 
	@ActionID int=0,    
    @status NVARCHAR(10),
	@deadheat FLOAT,
    @Remark VARCHAR(500) = '',	
	@IP varchar(15)=''
AS
/*
Creator: Dan
Date: 2013-07-16
DB: SVRLOG/LogDB, SVRTXN/LogDB
Task: Insert LOGS for outright settlement function

Revision:
	

*/

SET NOCOUNT ON;

INSERT INTO dbo.SettlementOutright
(	
	[UserId]
    ,[OrId]
	,LeagueId
    ,[ActionId]
    ,[status]
    ,[deadheat]
    ,[Remark]
    ,[IP]
) 
VALUES
(	
	@UserId
    ,@OrId
	,@LeagueId
    ,@ActionId
    ,@status
    ,@deadheat
    ,@Remark
    ,@IP
)

GO
GRANT EXECUTE ON [dbo].[WriteLog_Settlement_SettleOutright] TO [aplweb]
