alter PROCEDURE [dbo].[WriteLog_Settlement_Settle]
	@UserID int, 
	@MatchID int, 
	@ActionID int=0, 
	@finalhomescore INT,
    @finalawayscore INT,  
    @hthomescore INT,
    @htawayscore INT,
    @GoalRecord VARCHAR(50),
    @betstatus NVARCHAR(50),
    @Remark VARCHAR(500) = '',	
	@IP varchar(15)=''
AS
/*
Creator: Dan
Date: 2013-03-14
DB: CustomerLog
Task: Insert LOGS for settlement function

Revision:
	

*/

SET NOCOUNT ON;

INSERT INTO dbo.Settlement
(	
	UserID,
	MatchID,
	ActionID,
	[finalhomescore],
	[finalawayscore],  
    [hthomescore],
    [htawayscore],
    [GoalRecord],
    [betstatus],
    [Remark],
	IP
) 
VALUES
(	
	@UserID,
	@MatchID,
	@ActionID,
	@finalhomescore,
    @finalawayscore,  
    @hthomescore,
    @htawayscore,
    @GoalRecord,
    @betstatus,
    @Remark,	
	@IP
)

GO
GRANT EXECUTE ON [dbo].[WriteLog_Settlement_Settle] TO [aplweb]
