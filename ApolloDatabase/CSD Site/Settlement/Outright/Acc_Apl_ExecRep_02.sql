/****** Object:  StoredProcedure [dbo].[Acc_Set_ConfirmedAction]    Script Date: 5/29/2013 10:37:25 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[Acc_Apl_ExecRep_02]
@matchid int,
@actionid tinyint,
@status nvarchar(10),
@deadheat float
AS	
/**
 * Created by	: Dan
 * Date			: 20130712
 * Task			: Log settlement action for outright to apply in Apollo
 * DB			: SVRTRANS/TransDB
 * Revisions	:
 *	•
 * Parameters:	
	
 */

SET NOCOUNT ON	

	-- Insert into match_log
	INSERT INTO outright_log(
      [orid]
      ,[ActionId]
      ,[status]
      ,[deadheat]
	  )
	SELECT 
		@matchid
      ,@actionid
      ,@status
      ,@deadheat      	

	IF (@@SERVERNAME IN ('DB230\SQL2012', 'SDBTRANS1', 'SDBTRANS2')) -- TransDB server in Apollo system
		EXEC [Admin_AutoSettlement_GenerateCommandOutright]			
			@matchid = @matchid,
			@actionid = @actionid,
			@status = @status,
			@deadheat = @deadheat			
GO

GRANT EXECUTE ON [dbo].[Acc_Apl_ExecRep_02] TO [Dot_Admin]
