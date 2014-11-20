CREATE PROCEDURE [dbo].[Age_Customer_GetBalance]
(
	@CustID INT 
)
AS

BEGIN 
SET NOCOUNT ON 

SELECT SUM(ISNULL(Winlost,0) - ISNULL(Actual_Stake,0) + ISNULL(PlayerComm,0)) AS SportCredit FROM dbo.Bettrans WITH (NOLOCK) WHERE CustID = @CustID 

END
GO 
GRANT EXECUTE ON [dbo].[Age_Customer_GetBalance] TO [aplweb]
GO
 
  