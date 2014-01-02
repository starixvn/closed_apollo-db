SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Acc_SelRefNo]
	@refno int OUTPUT
AS
begin tran

UPDATE ref 
SET  @refno=refno=refno+1
WHERE refid='refno'

commit tran
GO
GRANT EXECUTE ON [dbo].[Acc_SelRefNo] TO [aplweb]	