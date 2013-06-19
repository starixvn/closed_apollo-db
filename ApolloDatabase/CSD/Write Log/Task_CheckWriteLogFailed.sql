GO
/****** Object:  StoredProcedure [dbo].[Task_CheckWriteLogFailed]    Script Date: 06/13/2013 04:42:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Task_CheckWriteLogFailed]

AS
BEGIN
	SET NOCOUNT ON	
	
	DECLARE	@ErrMsg	VARCHAR(8000)
	SELECT	@ErrMsg =''
	
	IF EXISTS(	SELECT TOP 1 1 FROM LoginAgent WITH (NOLOCK))
	BEGIN
		SELECT	@ErrMsg='WARNING: Writting LoginAgent failed! '
	END
	
	IF EXISTS(	SELECT TOP 1 1 FROM RunSpAgent WITH (NOLOCK))
	BEGIN
		SELECT	@ErrMsg= @ErrMsg +'WARNING: Writting RunSpAgent failed!'
	END
	
	IF EXISTS(	SELECT TOP 1 1 FROM RunSpCust WITH (NOLOCK))
	BEGIN
		SELECT	@ErrMsg= @ErrMsg +'WARNING: Writting RunSpCust failed!'
	END

	IF EXISTS(	SELECT TOP 1 1 FROM Settlement WITH (NOLOCK))
	BEGIN
		SELECT	@ErrMsg= @ErrMsg +'WARNING: Writting Settlement failed!'
	END
	
	IF @ErrMsg <> '' 
	BEGIN
		RAISERROR(@ErrMsg,16,1)
	END
	
END