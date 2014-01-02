USE [LogDB]
GO
/****** Object:  StoredProcedure [dbo].[WriteLog_ExchangeRate]    Script Date: 4/26/2013 4:42:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[WriteLog_ExchangeRate]
	@UserID int, 
	@ExchangeID INT, 
	@actualrate float, 
	@IP varchar(15)='',
	@Doing varchar(1000)=''
AS
/*
Creator: Sophia
Date: 20130317
DB: SVRLOG.LogDB
Task: Insert LOGS for update exchange rate

*/

SET NOCOUNT ON;

INSERT INTO dbo.Exchange(	UserID,
							ExchangeID,
							actualrate,
							Doing,								
							IP	) 
				VALUES	(	@UserID,
							@ExchangeID,
							@actualrate,
							@Doing,
							@IP)



GO
GRANT EXECUTE ON [dbo].[WriteLog_ExchangeRate] TO [aplweb]

