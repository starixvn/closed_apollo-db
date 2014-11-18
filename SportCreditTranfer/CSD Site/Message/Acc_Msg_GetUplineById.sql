IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Acc_Msg_GetUplineById')
	DROP PROC dbo.Acc_Msg_GetUplineById
GO
CREATE PROC dbo.Acc_Msg_GetUplineById
(
	 @IsAgent	BIT
	 , @Id		INT
)
AS
/*
* Created by	: Patrick
* Date			: 20131112
* Task			: Get upline for cust & agent by id
* DB			: SVRCSD/RepDB
* Parameters:
* Revisions	:
	20131216@Patrick	: Only get upline exclude this id
* Test string:
	exec dbo.Acc_Msg_GetUplineById 1, 100
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @AgentId INT
	SET @AgentId = @Id

	IF @IsAgent = 0
	BEGIN
		SELECT @AgentId = a.AgentId
		FROM dbo.CustInfo a WITH(NOLOCK)
		WHERE a.CustId = @Id
	END
	
	--++get upline
	;WITH SelfAndAncestor(TargetId, TargetName, ParentId)
	AS
	(
		SELECT AgentId, Username, ParentId--, AgentLevel
		FROM dbo.AgentInfo WITH (NOLOCK)
		WHERE AgentId = @AgentId

		UNION ALL

		SELECT a.AgentId, a.Username, a.ParentId--, a.AgentLevel
		FROM SelfAndAncestor AS b
		INNER JOIN dbo.AgentInfo AS a WITH (NOLOCK) ON b.ParentId = a.AgentId
	)

	--++
	SELECT TargetId, TargetName
	FROM SelfAndAncestor
	WHERE TargetId <> @AgentId
	
END
GO
GRANT EXECUTE ON [dbo].[Acc_Msg_GetUplineById] TO [aplweb]
GO
