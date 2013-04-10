USE [bodb_Message]
GO
/****** Object:  StoredProcedure [dbo].[Dot_Msg_HasPriMessage24]    Script Date: 4/2/2013 2:30:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
--exec [dbo].[Dot_Msg_HasPriMessage24] 1134121,0
ALTER PROCEDURE [dbo].[Dot_Msg_HasPriMessage24]
	-- Add the parameters for the stored procedure here
	@UserID int,
	@IsTest bit = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
declare @MessageID int
declare @PostTime datetime
	--if exists
		SELECT top 1 @MessageID=m.MessageID,@PostTime=m.PostTime FROM dbo.Msg m with (nolock)
		INNER JOIN dbo.MsgTarget mt with (nolock) ON m.MessageId = mt.MessageId and mt.TargetId=@UserID
		WHERE m.MsgType=1  
		--AND m.MessageId > 50000
		AND m.IsSticky = 0
		AND case @IsTest when 1 then 1
			when m.IsTest then 1
			end = 1
		and m.posttime > dateadd(d,-1,getdate()) 
		ORDER BY m.PostTime DESC
		--set @MessageID = MessageID
	--else
	--	set @MessageID = 0

if @@rowcount>0
	select @MessageID as MessageID, @PostTime as Posttime
else
	select 0 as MessageID, null as PostTime
END

