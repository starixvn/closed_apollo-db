USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetByAgent]    Script Date: 3/29/2013 10:05:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_GetByAgent]
	@AgentId	INT,
	@UserName	VARCHAR(50) = '',
	@PageSize	INT = 20000,
	@PageIndex	INT = 1,
	@TotalPages	INT = 1 OUTPUT,
	@TotalItems	INT = 0 OUTPUT		
AS
/**
 * Created by	: Terry.Nguyen
 * Date			: 20130306
 * Task			: Retrieve all player by agent
 * DB			: APL.DB05
 * Revisions	:
 *	• 20130328@Terry.Nguyen: get active col. Noted that 0/1/2 is Active/Suspended/Closed
 * Parameters:
 *	•
 *	•
 *  
 */
BEGIN
	SET NOCOUNT ON	

	DECLARE @RowCount	INT, @RowStart	INT, @RowEnd	INT
	SELECT	@PageIndex = @PageIndex - 1,
			@RowStart = @PageSize * @PageIndex + 1,
			@RowEnd = @RowStart + @PageSize - 1

	SET @UserName = ISNULL(@UserName,'')

	IF(@UserName = '')
		BEGIN
			SELECT @TotalItems = COUNT(p.CustId), @TotalPages = @TotalItems/@PageSize + CASE WHEN @TotalItems % @PageSize > 0 THEN 1 ELSE 0 END
			FROM CustInfo p WITH(NOLOCK) 				 
			WHERE p.AgentId = @AgentId

			SELECT * FROM (

						SELECT
							p.CustId, 
							p.Username,
							(CASE WHEN p.Closed = 1 THEN 2 ELSE CASE WHEN p.Suspended = 1 THEN 1 ELSE 0 END END) AS Active,								
							MAX(CASE WHEN cp.BetType = 1  AND cp.IsLive = 0 THEN cp.PositionTaking ELSE 0 END) as HDP_Soccer_PT,
							MAX(CASE WHEN cp.BetType = 3  AND cp.IsLive = 0 THEN cp.PositionTaking ELSE 0 END) as OU_Soccer_PT,							
							MAX(CASE WHEN cp.BetType = 1  AND cp.IsLive = 1 THEN cp.PositionTaking ELSE 0 END) as HDP_Soccer_PT_Live,
							MAX(CASE WHEN cp.BetType = 3  AND cp.IsLive = 1 THEN cp.PositionTaking ELSE 0 END) as OU_Soccer_PT_Live,														
							p.UGroup,

							MAX(CASE WHEN pd.BetType = 1 THEN pd.Discount ELSE 0 END) AS CustGroup,
							MAX(CASE WHEN pd.BetType = 5 THEN pd.Discount ELSE 0 END) AS CustDiscount1x2,
							MAX(CASE WHEN pd.BetType = 4 THEN pd.Discount ELSE 0 END) AS CustDiscountOther,
							ISNULL(pd3rd.Discount, 0) AS CustDiscountNumberGame,

							MAX(CASE WHEN ad.BetType = 1  THEN ad.DiscountA ELSE 0 END) AS AgentGroup,
							MAX(CASE WHEN ad.BetType = 5  THEN ad.DiscountA ELSE 0 END) AS AgentDiscount1x2,
							MAX(CASE WHEN ad.BetType = 4  THEN ad.DiscountA ELSE 0 END) AS AgentDiscountOther,
							ISNULL(ad3rd.DiscountA, 0) AS AgentDiscountNumberGame,

						
							ROW_NUMBER() OVER(ORDER BY p.Username) AS RowNumber
						FROM CustInfo p WITH(NOLOCK) 
							INNER JOIN (SELECT CustId, Discount, BetType FROM CustDiscount WITH(NOLOCK) 
										WHERE CustId = @AgentId AND SportType = 1 AND BetType IN(1,4,5)
										GROUP BY CustId,Discount, BetType) pd ON pd.CustId = p.AgentId

							INNER JOIN (SELECT CustId, Discount FROM CustDiscount3rd WITH(NOLOCK) 
										WHERE CustId = @AgentId AND SportType = 161 AND BetType = 81
										GROUP BY CustId, Discount) pd3rd ON pd3rd.CustId = p.AgentId
													
							INNER JOIN (SELECT AgentId, DiscountA, DiscountB, DiscountC, DiscountD, BetType FROM AgentDiscount WITH(NOLOCK)
										WHERE AgentId = @AgentId AND SportType = 1 AND BetType IN(1,4,5) 
										GROUP BY AgentId, DiscountA, DiscountB, DiscountC, DiscountD, BetType) ad ON ad.AgentId = p.AgentId

							INNER JOIN (SELECT AgentId, DiscountA FROM AgentDiscount3rd WITH(NOLOCK) 
										WHERE AgentId = @AgentId AND SportType = 161 AND BetType = 81 
										GROUP BY AgentId, DiscountA) ad3rd ON ad3rd.AgentId = p.AgentId

							INNER JOIN(SELECT AgentId, PositionTaking, IsLive, BetType FROM CustPositionTaking WITH(NOLOCK) 
									   WHERE AgentId = @AgentId AND SportType = 1 AND BetType IN(1,3) 
									   GROUP BY AgentId, PositionTaking, IsLive,BetType) cp ON cp.AgentId = p.AgentId

				
						WHERE p.AgentId = @AgentId
						GROUP BY 
						p.CustId,
						p.Username,
						p.UGroup,
						pd3rd.Discount,
						ad3rd.DiscountA,
						p.Closed,
						p.Suspended					
			) b
			WHERE b.RowNumber BETWEEN @RowStart AND @RowEnd
			ORDER BY Active, Username
		END
	ELSE
		BEGIN
			SELECT @TotalItems = COUNT(p.CustId), @TotalPages = @TotalItems/@PageSize + CASE WHEN @TotalItems % @PageSize > 0 THEN 1 ELSE 0 END
			FROM CustInfo p WITH(NOLOCK) 				 
			WHERE p.AgentId = @AgentId ANd p.Username LIKE '%' + @UserName + '%'

			SELECT * FROM (

						SELECT
							p.CustId, 
							p.Username,
							(CASE WHEN p.Closed = 1 THEN 2 ELSE CASE WHEN p.Suspended = 1 THEN 1 ELSE 0 END END) AS Active,								
							MAX(CASE WHEN cp.BetType = 1  AND cp.IsLive = 0 THEN cp.PositionTaking ELSE 0 END) as HDP_Soccer_PT,
							MAX(CASE WHEN cp.BetType = 3  AND cp.IsLive = 0 THEN cp.PositionTaking ELSE 0 END) as OU_Soccer_PT,							
							MAX(CASE WHEN cp.BetType = 1  AND cp.IsLive = 1 THEN cp.PositionTaking ELSE 0 END) as HDP_Soccer_PT_Live,
							MAX(CASE WHEN cp.BetType = 3  AND cp.IsLive = 1 THEN cp.PositionTaking ELSE 0 END) as OU_Soccer_PT_Live,														
							p.UGroup,

							MAX(CASE WHEN pd.BetType = 1 THEN pd.Discount ELSE 0 END) AS CustGroup,
							MAX(CASE WHEN pd.BetType = 5 THEN pd.Discount ELSE 0 END) AS CustDiscount1x2,
							MAX(CASE WHEN pd.BetType = 4 THEN pd.Discount ELSE 0 END) AS CustDiscountOther,
							ISNULL(pd3rd.Discount, 0) AS CustDiscountNumberGame,

							MAX(CASE WHEN ad.BetType = 1  THEN ad.DiscountA ELSE 0 END) AS AgentGroup,
							MAX(CASE WHEN ad.BetType = 5  THEN ad.DiscountA ELSE 0 END) AS AgentDiscount1x2,
							MAX(CASE WHEN ad.BetType = 4  THEN ad.DiscountA ELSE 0 END) AS AgentDiscountOther,
							ISNULL(ad3rd.DiscountA, 0) AS AgentDiscountNumberGame,

						
							ROW_NUMBER() OVER(ORDER BY p.Username) AS RowNumber
						FROM CustInfo p WITH(NOLOCK) 
							INNER JOIN (SELECT CustId, Discount, BetType FROM CustDiscount WITH(NOLOCK) 
										WHERE CustId = @AgentId AND SportType = 1 AND BetType IN(1,4,5)
										GROUP BY CustId,Discount, BetType) pd ON pd.CustId = p.AgentId

							INNER JOIN (SELECT CustId, Discount FROM CustDiscount3rd WITH(NOLOCK) 
										WHERE CustId = @AgentId AND SportType = 161 AND BetType = 81
										GROUP BY CustId, Discount) pd3rd ON pd3rd.CustId = p.AgentId
													
							INNER JOIN (SELECT AgentId, DiscountA, DiscountB, DiscountC, DiscountD, BetType FROM AgentDiscount WITH(NOLOCK)
										WHERE AgentId = @AgentId AND SportType = 1 AND BetType IN(1,4,5) 
										GROUP BY AgentId, DiscountA, DiscountB, DiscountC, DiscountD, BetType) ad ON ad.AgentId = p.AgentId

							INNER JOIN (SELECT AgentId, DiscountA FROM AgentDiscount3rd WITH(NOLOCK) 
										WHERE AgentId = @AgentId AND SportType = 161 AND BetType = 81 
										GROUP BY AgentId, DiscountA) ad3rd ON ad3rd.AgentId = p.AgentId

							INNER JOIN(SELECT AgentId, PositionTaking, IsLive, BetType FROM CustPositionTaking WITH(NOLOCK) 
									   WHERE AgentId = @AgentId AND SportType = 1 AND BetType IN(1,3) 
									   GROUP BY AgentId, PositionTaking, IsLive,BetType) cp ON cp.AgentId = p.AgentId

				
						WHERE p.AgentId = @AgentId AND P.Username LIKE + '%' + @UserName + '%'
						GROUP BY 
						p.CustId,
						p.Username,
						p.UGroup,
						pd3rd.Discount,
						ad3rd.DiscountA,	
						p.Closed,
						p.Suspended		
									
						
			) b
			WHERE b.RowNumber BETWEEN @RowStart AND @RowEnd
			ORDER BY Active, Username
		END
END
