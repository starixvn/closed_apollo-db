/****** Object:  StoredProcedure [dbo].[Acc_Set_ConfirmedActionParlay]    Script Date: 5/29/2013 10:37:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Acc_Set_ConfirmedActionParlay]
(
	@matchids	VARCHAR(2000)
) 
AS
/**
 * Created by	: Kaden
 * Date			: 20130402
 * Task			: Update Confirmed Action value for Mix Parlay
 * DB			: SVRTRANS/TransDB
 * Revisions	:
 *	•
 * Parameters:
	@MatchIDs: list matchId
 */
SET NOCOUNT ON

BEGIN
	EXEC Acc_Apl_ExecRep_01 @matchids=@matchids
END
GO

GRANT EXECUTE ON [dbo].[Acc_Set_ConfirmedActionParlay] TO [bodbAdminNet]	