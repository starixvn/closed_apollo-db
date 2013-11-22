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
* Test string:
	exec dbo.Acc_Msg_GetUplineById 1, 3
	exec dbo.Acc_Msg_GetUplineById 0, 72
* Revisions	:

select * from [dbo].[AdminInfo] where username = 'sa'

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
	;WITH SelfAndAncestor(AgentId)
	AS
	(
		SELECT AgentId
		FROM dbo.AgentInfo WITH (NOLOCK)
		WHERE AgentId = @AgentId

		UNION ALL

		SELECT a.ParentId
		FROM dbo.AgentInfo AS a WITH (NOLOCK)
		INNER JOIN SelfAndAncestor AS b ON a.AgentId = b.AgentId
	)

	--++
	SELECT *
	FROM
	(
		--++for cust
		SELECT @Id AS 'TargetId', Username AS 'TargetName'--, null
		FROM dbo.CustInfo WITH(NOLOCK)
		WHERE 0 = @IsAgent AND CustId = @Id

		UNION ALL

		SELECT b.AgentId AS 'TargetId', b.Username AS 'TargetName'--, b.AgentLevel
		FROM SelfAndAncestor a
		JOIN dbo.AgentInfo b ON a.AgentId = b.AgentId
	)a
END
GO
GRANT EXECUTE ON [dbo].[Acc_Msg_GetUplineById] TO [aplweb]
GO
