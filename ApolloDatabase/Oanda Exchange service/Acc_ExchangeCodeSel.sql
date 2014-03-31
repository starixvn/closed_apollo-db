
/****** Object:  StoredProcedure [dbo].[Acc_ExchangeCodeSel]    Script Date: 03/05/2014 20:06:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[Acc_ExchangeCodeSel]
AS
/*
Created: 2014/03/06@Dan
Task : Get the list of Code need to get the exchange rate
DB: SVRCSD/RepDB
Revisions:
	
*/		
	SET NOCOUNT ON

	SELECT DISTINCT CODE 
	FROM exchange WITH (nolock)
	WHERE ISNULL(Code,'') <> '' 		
		--AND Code in ('GBP', 'TWD')


GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeCodeSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeCodeSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeCodeSel] TO [aplweb] AS [dbo]