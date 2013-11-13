IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Acc_Msg_GetRecipientInfo')
	DROP PROC dbo.Acc_Msg_GetRecipientInfo
GO
CREATE PROC dbo.Acc_Msg_GetRecipientInfo
(
	 @IsAgent BIT
	 , @Username VARCHAR(50)
)
AS
/*
* Created by	: Patrick
* Date			: 20131112
* Task			: Get recipient info
* DB			: SVRCUST/CUSTDB
* Parameters:
* Test string:
	exec dbo.Acc_Msg_GetRecipientInfo 1, 'super'

* Revisions	:

*/
BEGIN
	SET NOCOUNT ON
	IF @IsAgent = 0
	BEGIN
		SELECT CustId, Username
		FROM dbo.CustInfo WITH(NOLOCK)
		WHERE Username = @Username
	END
	ELSE
	BEGIN
		SELECT AgentId, Username
		FROM dbo.AgentInfo WITH(NOLOCK)
		WHERE Username = @Username
	END

END
GO
GRANT EXECUTE ON [dbo].[Acc_Msg_GetRecipientInfo] TO [aplweb]
GO
