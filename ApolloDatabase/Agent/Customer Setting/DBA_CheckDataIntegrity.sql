USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[DBA_CheckDataIntegrity]    Script Date: 8/12/2013 10:28:21 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[DBA_CheckDataIntegrity]	
AS

/**
 * Created by	: Kos
 * Date			: 20130305
 * Task			: Check data integrity
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	• 
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON	

	PRINT '----------------------------------------------------------------'
	PRINT 'Agent'

	IF EXISTS (	SELECT 1 
				FROM AgentInfo AS ai WITH (NOLOCK)
				WHERE 
					ai.AgentId > 1 
					AND NOT EXISTS ( SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE AgentId = ai.ParentId ) )
		PRINT 'Unknown Parent : Failed'
	ELSE
		PRINT 'Unknown Parent : OK'
	
	PRINT '----------------------------------------------------------------'
	PRINT 'Agent Bet Limit'

	IF EXISTS (	SELECT 1 
				FROM AgentInfo AS ai WITH (NOLOCK)
				WHERE NOT EXISTS ( SELECT 1 FROM AgentBetLimit WITH (NOLOCK) WHERE AgentId = ai.AgentId ) )
		PRINT 'No Setting : Failed'
	ELSE
		PRINT 'No Setting : OK'

	IF EXISTS (	SELECT 1 
				FROM AgentBetLimit AS abl WITH (NOLOCK)
				WHERE NOT EXISTS ( SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE AgentId = abl.AgentId ) )
		PRINT 'Unknown Agent : Failed'
	ELSE
		PRINT 'Unknown Agent : OK'

	PRINT '----------------------------------------------------------------'
	PRINT 'Agent Discount'

	IF EXISTS (	SELECT 1 
				FROM AgentInfo AS ai WITH (NOLOCK)
				WHERE NOT EXISTS ( SELECT 1 FROM AgentDiscount WITH (NOLOCK) WHERE AgentId = ai.AgentId ) )
		PRINT 'No Setting : Failed'
	ELSE
		PRINT 'No Setting : OK'

	IF EXISTS (	SELECT 1 
				FROM AgentDiscount AS ad WITH (NOLOCK)
				WHERE NOT EXISTS ( SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE AgentId = ad.AgentId ) )
		PRINT 'Unknown Agent : Failed'
	ELSE
		PRINT 'Unknown Agent : OK'

	PRINT '----------------------------------------------------------------'
	PRINT 'Agent Position Taking'

	IF EXISTS (	SELECT 1 
				FROM AgentInfo AS ai WITH (NOLOCK)
				WHERE NOT EXISTS ( SELECT 1 FROM AgentPositionTaking WITH (NOLOCK) WHERE AgentId = ai.AgentId ) )
		PRINT 'No Setting : Failed'
	ELSE
		PRINT 'No Setting : OK'

	IF EXISTS (	SELECT 1 
				FROM AgentPositionTaking AS apt WITH (NOLOCK)
				WHERE NOT EXISTS ( SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE AgentId = apt.AgentId ) )
		PRINT 'Unknown Agent : Failed'
	ELSE
		PRINT 'Unknown Agent : OK'

	PRINT '----------------------------------------------------------------'
	PRINT 'Customer'

	IF EXISTS (	SELECT 1 
				FROM CustInfo AS ci WITH (NOLOCK)
				WHERE NOT EXISTS ( SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE AgentId = ci.AgentId ) )
		PRINT 'Unknown Agent : Failed'
	ELSE
		PRINT 'Unknown Agent : OK'

	PRINT '----------------------------------------------------------------'
	PRINT 'Customer Bet Limit'

	IF EXISTS (	SELECT 1 
				FROM CustInfo AS ci WITH (NOLOCK)
				WHERE NOT EXISTS ( SELECT 1 FROM CustBetLimit WITH (NOLOCK) WHERE CustId = ci.CustId ) )
		PRINT 'No Setting : Failed'
	ELSE
		PRINT 'No Setting : OK'

	IF EXISTS (	SELECT 1 
				FROM CustBetLimit AS cbl WITH (NOLOCK)
				WHERE NOT EXISTS ( SELECT 1 FROM CustInfo WITH (NOLOCK) WHERE CustId = cbl.CustId ) )
		PRINT 'Unknown Customer : Failed'
	ELSE
		PRINT 'Unknown Customer : OK'

	PRINT '----------------------------------------------------------------'
	PRINT 'Customer Discount'

	IF EXISTS (	SELECT 1 
				FROM CustInfo AS ci WITH (NOLOCK)
				WHERE NOT EXISTS ( SELECT 1 FROM CustDiscount WITH (NOLOCK) WHERE CustId = ci.CustId ) )
		PRINT 'No Setting : Failed'
	ELSE
		PRINT 'No Setting : OK'

	IF EXISTS (	SELECT 1 
				FROM CustDiscount AS cd WITH (NOLOCK)
				WHERE NOT EXISTS ( SELECT 1 FROM CustInfo WITH (NOLOCK) WHERE CustId = cd.CustId ) )
		PRINT 'Unknown Customer : Failed'
	ELSE
		PRINT 'Unknown Customer : OK'

	PRINT '----------------------------------------------------------------'
	PRINT 'Customer Position Taking'

	IF EXISTS (	SELECT 1 
				FROM CustInfo AS ci WITH (NOLOCK)
				WHERE NOT EXISTS ( SELECT 1 FROM CustPositionTaking WITH (NOLOCK) WHERE CustId = ci.CustId ) )
		PRINT 'No Setting : Failed'
	ELSE
		PRINT 'No Setting : OK'

	IF EXISTS (	SELECT 1 
				FROM CustPositionTaking AS cpt WITH (NOLOCK)
				WHERE NOT EXISTS ( SELECT 1 FROM CustInfo WITH (NOLOCK) WHERE CustId = cpt.CustId ) )
		PRINT 'Unknown Customer : Failed'
	ELSE
		PRINT 'Unknown Customer : OK'
		
END	




