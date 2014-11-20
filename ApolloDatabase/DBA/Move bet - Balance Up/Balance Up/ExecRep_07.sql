USE [TransDB]
GO
/****** Object:  StoredProcedure [dbo].[ExecRep_07]    Script Date: 6/6/2013 4:32:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ExecRep_07]
	@custids varchar(2000),
	@isAgent TINYINT,
	@IsCreditTrans TINYINT = 0,
	@winlostdate smalldatetime

AS
/*
	Created by: Dan
	Date: 2013-06-04
	Task: Delete bettrans after balance-up 
	DB: SVRTXN.TransDB
	Orginal SP: bodb02.ExecRep_07

	Revisions:
		- 20141118@Sophia: Add Param @IsCreditTrans to delete table CreditTrans
		
*/
--SET NOCOUNT ON

	BEGIN TRY
		BEGIN TRANSACTION
			IF @IsCreditTrans = 0 
			BEGIN 

				IF @isAgent = 0 -- for customers
				BEGIN
					DELETE FROM bettrans
					WHERE CustId IN (SELECT val FROM dbo.strSplit(@custids, ','))
					AND ruben = 1 AND winlostdate < @winlostdate
				END
				ELSE -- for agents
				BEGIN
						
					--DELETE OLD BALANCE
					DELETE B			
					FROM BetTrans_Agent BA JOIN Bettrans B ON BA.Transid=B.Transid
					WHERE AgentId IN (SELECT val FROM dbo.strSplit(@custids, ','))
						AND B.ruben = 1 AND B.winlostdate < @winlostdate
						AND B.BETTYPE=20000 
						AND BA.winlostdate < @winlostdate				 
				
					DELETE BA			
					FROM BetTrans_Agent BA --JOIN Bettrans B ON BA.Transid=B.Transid
					WHERE AgentId IN (SELECT val FROM dbo.strSplit(@custids, ','))
						AND BA.STatusID NOT IN (0,1) 
						AND BA.winlostdate < @winlostdate
				END
			END 
			ELSE IF @IsCreditTrans = 1
			BEGIN 
				DELETE FROM dbo.CreditTrans
				WHERE AgentId IN (SELECT val FROM dbo.strSplit(@custids, ','))
					  AND winlostdate < @winlostdate
			END 
		COMMIT TRANSACTION
		
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;

		SELECT 
			@ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();
		
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION --RollBack in case of Error

		-- Use RAISERROR inside the CATCH block to return error
		-- information about the original error that caused
		-- execution to jump to the CATCH block.
		RAISERROR (@ErrorMessage,  @ErrorSeverity,  @ErrorState )

	END CATCH
