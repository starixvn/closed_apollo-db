USE [TransDB]
GO
/****** Object:  StoredProcedure [dbo].[Mem_API_GetExchange]    Script Date: 9/10/2013 1:37:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Mem_API_GetExchange]	
	@Currency	NVARCHAR(5),
	@exchangeid	INT			OUTPUT
AS

/**
 * Created by	: Kos
 * Date			: 20130910
 * Task			: Get exchangeid from Currency
 * DB			: SVRTXN.TransDB
 * Revisions	:
 *	•	
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN 
	SET NOCOUNT ON

	SELECT @exchangeid = exchangeid
	FROM dbo.Exchange WITH (NOLOCK)
	WHERE Currency = @Currency

END

