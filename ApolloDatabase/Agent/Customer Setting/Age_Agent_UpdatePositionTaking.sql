USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_UpdatePositionTaking]    Script Date: 7/17/2013 4:22:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 /*
USE [CustDB]
GO

DECLARE	@return_value int,
		@ErrCode int,
		@ErrMsg nvarchar(1000)

EXEC	@return_value = [dbo].Age_Agent_UpdatePositionTaking
		@ActorAgentId = 180,
		@AgentId = 185,
		@PositionTaking = N'<ROOT>
							<PositionTaking SportType="1" BetType="1" IsLive="0" MaxUpper="122" MaxGiven="7761" MinGiven="0"></PositionTaking>
							<PositionTaking SportType="1" BetType="1" IsLive="1" MaxUpper="122" MaxGiven="7962" MinGiven="0"></PositionTaking>
						</ROOT>',
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT

SELECT	@ErrCode as N'@ErrCode',
		@ErrMsg as N'@ErrMsg'


SELECT	'Return Value' = @return_value

GO

*/
ALTER PROCEDURE [dbo].[Age_Agent_UpdatePositionTaking]
	@ActorAgentId		INT				= NULL,
	@AdminId			INT				= NULL,
	@AgentId			INT,
	@PositionTaking		VARCHAR(MAX)	= '',	
	@Language			VARCHAR(5)		= 'en-US',	
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsg				NVARCHAR(1000)	= ''		OUTPUT
AS

/**
 * Created by	: Edward
 * Date			: 20130410
 * Task			: Update agent position taking
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	• 20131707@Edward	: Add parameter @AdminId for write log
 * Parameters:
 *	@PositionTaking :
		<ROOT><PositionTaking SportType="1" BetType="1" IsLive="0" MaxUpper="122" MaxGiven="7761" MinGiven="0"></PositionTaking></ROOT>		
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	-- Check update permission
	DECLARE @hasPermission BIT

	EXEC dbo.Age_Agent_CheckUpdatePermission 
		@ActorAgentId,
		@AgentId,
		1,				-- Is Agent
		@hasPermission OUTPUT 
	
	IF @hasPermission = 0
		BEGIN
			SELECT 
				@ErrCode = 1000,
				@ErrMsg	= 
					CASE @Language
						WHEN 'en-US' THEN 'You do not have permission to update setting'
						ELSE [dbo].f_Msg_GetContentById (1000, @Language)
					END

			RETURN
		END
		
	-- For write log
	DECLARE 
		@startRun		DATETIME,
		@endRun			DATETIME,
		@duration		INT,
		@logSPData		VARCHAR(5000),
		@logSPDataOld	VARCHAR(5000),
		@xml			XML

	SET @startRun = GETDATE()
		
	-- begin update	
	IF @PositionTaking <> ''
		BEGIN
		
			-- Declare variable
			DECLARE 
				@agentHId			HIERARCHYID
				,@parentAgentId		INT
				,@agentLevel		SMALLINT
				,@sportType			SMALLINT
				,@betType			SMALLINT
				,@isLive			BIT
				,@tempAgentId		INT
				,@tempUsername		NVARCHAR(50)
				,@isLastAgent		BIT
				,@currentCustId		INT
				,@data				VARCHAR(MAX)
				,@tempLevel			INT

			---- Declare agentId
			DECLARE 
				@agentParentLevel		SMALLINT
				,@agentParentHId		HIERARCHYID
				,@parentOfParentAgentId	INT
				,@currentAgentId		INT
				,@childCurrentAgentId	INT
			---- End declare

			-- Select for current Agent
			SELECT 
				@agentLevel		= AgentLevel
				,@agentHId		= AgentHId
				,@parentAgentId = ParentId
			FROM AgentInfo WITH (NOLOCK)
			WHERE AgentId = @AgentId

			-- Select for parent
			SELECT 
				@agentParentLevel		= AgentLevel
				,@agentParentHId		= AgentHId
				,@parentOfParentAgentId = ParentId
			FROM AgentInfo WITH (NOLOCK)
			WHERE AgentId = @parentAgentId

			---- End set value

			-- Declare constant
			DECLARE	
				@MAINSHAREHOLDERLEVEL	SMALLINT	= 1
				,@SHAREHOLDERLEVEL		SMALLINT	= 2
				,@MAINAGENTLEVEL		SMALLINT	= 3
				,@MAXPT					SMALLINT	= 10000
				,@MAXSHAREHOLDERPT		SMALLINT	= 9000
				,@MINSHAREMUSTCOVER		SMALLINT	= 5000

			-- Check current agent is last agent ?
			IF EXISTS ( SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE ParentId = @AgentId )
				SET @isLastAgent = 0
			ELSE
				SET @isLastAgent = 1

			-- Store new position taking of agent
			DECLARE @TablePositionTaking TABLE (
				SportType	SMALLINT,
				BetType		SMALLINT,
				IsLive		BIT,
				MaxUpperPT	SMALLINT,
				MaxGivenPT	SMALLINT,
				MinGivenPT	SMALLINT)
		
			DECLARE @TableUpdatePositionTaking TABLE (
				SportType	SMALLINT,
				BetType		SMALLINT,
				IsLive		BIT,
				MaxUpperPT	SMALLINT,
				MaxGivenPT	SMALLINT,
				MinGivenPT	SMALLINT)		
	
			DECLARE @TableCust TABLE (CustId INT)

			DECLARE @TableChildAgent TABLE (AgentId INT)

			DECLARE @TableCustPositionTaking TABLE (
				CustId				INT,
				SportType			SMALLINT,
				BetType				SMALLINT,
				IsLive				BIT,
				PositionTaking		SMALLINT)

			-- For update Cust Position Taking
		
			DECLARE @TableStackPositionTaking TABLE (
				AgentId		INT,
				AgentLevel	SMALLINT,
				SportType	SMALLINT,
				BetType		SMALLINT,
				IsLive		BIT,
				PT			SMALLINT,
				MinPT		SMALLINT,
				SumDownPT	SMALLINT)
								
			DECLARE @TableUpdateCustPositionTaking TABLE (
				AgentId		INT,
				SportType	SMALLINT,
				BetType		SMALLINT,
				IsLive		BIT,
				PT			SMALLINT,
				Preset		SMALLINT,
				Result		SMALLINT,
				IsDeleted	BIT)
		
			DECLARE @TableTempPositionTaking TABLE (
				AgentId		INT,
				AgentLevel	SMALLINT,
				SportType	SMALLINT,
				BetType		SMALLINT,
				IsLive		BIT,
				PT			SMALLINT,
				Preset		SMALLINT)

			DECLARE @TableTempAgent TABLE (AgentId INT)

			DECLARE @TableCustAgent TABLE (
				CustId		INT, 
				AgentId		INT,
				AgentLevel	SMALLINT)

			DECLARE @UplineAgentInfo TABLE (
				AgentId		INT,
				AgentLevel	SMALLINT,
				ParentId	INT)
			-- End for update Cust Position Taking
			-- For read xml
			DECLARE @DocHandler INT

			EXEC sp_xml_preparedocument @DocHandler OUTPUT, @PositionTaking

			INSERT INTO @TablePositionTaking(
				SportType,
				BetType,
				IsLive,
				MaxUpperPT,
				MaxGivenPT,
				MinGivenPT)
			SELECT
				Data.SportType,
				Data.BetType,
				Data.IsLive,
				Data.MaxUpper,
				Data.MaxGiven,
				Data.MinGiven
			FROM OPENXML (@DocHandler, '/ROOT/PositionTaking',1) 
			WITH (
				SportType	SMALLINT,
				BetType		SMALLINT,
				IsLive		BIT,
				MaxUpper	SMALLINT,
				MaxGiven	SMALLINT,
				MinGiven	SMALLINT
			) AS Data

			EXEC sp_xml_removedocument @DocHandler
			-- end read xml	

			-- Check validate max and min
			SELECT TOP(1) 
				@sportType	= SportType
				,@betType	= BetType
				,@isLive	= IsLive
			FROM @TablePositionTaking
			WHERE MinGivenPT	< 0
				OR MaxGivenPT	< 0
				OR MaxUpperPT	< 0 

			IF @sportType IS NOT NULL 
				BEGIN
					SELECT 
						@ErrCode = 4002,
						@ErrMsg	= 
							CASE @Language
								WHEN 'en-US' THEN '% must be equal or greater than zero' 
								ELSE [dbo].f_Msg_GetContentById (4002, @Language)
							END + ' (' 
								+ CASE WHEN @sportType = 99 AND @betType = 9
										THEN [dbo].f_Msg_GetContentById (4009, @Language)
										ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
									END
								+ CASE WHEN @isLive = 1 THEN + ' ' + [dbo].f_Msg_GetContentById (4008, @Language) 
										ELSE '' 
									END
								+ ' - ' + dbo.f_Bet_GetNameByType(@betType, @Language) 
								+')'

					RETURN
				END	

			-- Check validate max and min
			SELECT TOP(1) 
				@sportType	= SportType
				,@betType	= BetType
				,@isLive	= IsLive
			FROM @TablePositionTaking
			WHERE MinGivenPT > MaxGivenPT

			IF @sportType IS NOT NULL 
				BEGIN
					SELECT 
						@ErrCode = 4003,
						@ErrMsg	= 
							CASE @Language
								WHEN 'en-US' THEN '% Min Downline must be equal to or less than % Downline' 
								ELSE [dbo].f_Msg_GetContentById (4003, @Language)
							END + ' (' 
								+ CASE WHEN @sportType = 99 AND @betType = 9
										THEN [dbo].f_Msg_GetContentById (4009, @Language)
										ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
									END
								+ CASE WHEN @isLive = 1 THEN + ' ' + [dbo].f_Msg_GetContentById (4008, @Language) 
										ELSE '' 
									END
								+ ' - ' + dbo.f_Bet_GetNameByType(@betType, @Language) 
								+')'

					RETURN
				END	

			SELECT TOP(1) 
				@sportType		= tpt.SportType
				,@tempAgentId	= apt.AgentId
				,@betType		= tpt.BetType
				,@isLive		= tpt.IsLive
			FROM @TablePositionTaking AS tpt
				INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
					ON apt.SportType	= tpt.SportType
					AND apt.BetType		= tpt.BetType
					AND apt.IsLive		= tpt.IsLive				
			WHERE tpt.MaxUpperPT + tpt.MaxGivenPT > apt.MaxGivenPositionTaking
				AND apt.AgentId = @parentAgentId

			SELECT @tempUsername = Username 
			FROM AgentInfo WITH (NOLOCK)
			WHERE AgentId = @tempAgentId

			IF @sportType IS NOT NULL 
				BEGIN
					SELECT 
						@ErrCode = 4001,
						@ErrMsg	= 
							CASE @Language
								WHEN 'en-US' THEN 'Sum % Preset and % Downline must be equal or less than % Downline of Parent Agent' 
								ELSE [dbo].f_Msg_GetContentById (4001, @Language)
							END + ' ('+ @tempUsername +')' 
								+ ' (' 
								+ CASE WHEN @sportType = 99 AND @betType = 9
										THEN [dbo].f_Msg_GetContentById (4009, @Language)
										ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
									END
								+ CASE WHEN @isLive = 1 THEN + ' ' + [dbo].f_Msg_GetContentById (4008, @Language) 
										ELSE '' 
									END
								+ ' - ' + dbo.f_Bet_GetNameByType(@betType, @Language) 
								+')'

					RETURN
				END	
		
			SELECT TOP(1) 
				@sportType	= tpt.SportType
				,@betType	= tpt.BetType
				,@isLive	= tpt.IsLive
			FROM 
				@TablePositionTaking AS tpt
				INNER JOIN AgentPositionTaking AS papt WITH (NOLOCK)
					ON tpt.SportType	= papt.SportType
					AND tpt.BetType		= papt.BetType
					AND tpt.IsLive		= papt.IsLive
			WHERE 
				papt.AgentId = @parentAgentId
				AND tpt.MaxUpperPT NOT BETWEEN CASE WHEN papt.MinGivenPositionTaking - tpt.MaxGivenPT > 0 
													THEN papt.MinGivenPositionTaking - tpt.MaxGivenPT
													ELSE 0
												END AND papt.MaxGivenPositionTaking - tpt.MaxGivenPT

			IF @sportType IS NOT NULL 
				BEGIN
					SELECT 
						@ErrCode	= 4000,
						@ErrMsg		= 
							CASE @Language
								WHEN 'en-US' THEN 'Invalid % range' 
								ELSE [dbo].f_Msg_GetContentById (4000, @Language)
							END + ' (' 
								+ CASE WHEN @sportType = 99 AND @betType = 9
										THEN [dbo].f_Msg_GetContentById (4009, @Language)
										ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
									END
								+ CASE WHEN @isLive = 1 THEN + ' ' + [dbo].f_Msg_GetContentById (4008, @Language) 
										ELSE '' 
									END
								+ ' - ' + dbo.f_Bet_GetNameByType(@betType, @Language) 
								+')'

					RETURN
				END

			SELECT TOP(1) 
				@sportType	= tpt.SportType
				,@betType	= tpt.BetType
				,@isLive	= tpt.IsLive
			FROM @TablePositionTaking AS tpt					
			WHERE (@agentLevel < @MAINAGENTLEVEL AND tpt.MaxGivenPT	< @MINSHAREMUSTCOVER)
					OR( @agentLevel			= @MAINAGENTLEVEL
						AND (tpt.MaxGivenPT	< @MINSHAREMUSTCOVER					   
						OR tpt.MinGivenPT	< @MINSHAREMUSTCOVER ))

			IF @sportType IS NOT NULL 
				BEGIN
					SELECT 
						@ErrCode	= 4010,
						@ErrMsg		= 
							CASE @Language
								WHEN 'en-US' THEN 'Invalid % share' 
								ELSE [dbo].f_Msg_GetContentById (4010, @Language)
							END + ' (' 
								+ CASE WHEN @sportType = 99 AND @betType = 9
										THEN [dbo].f_Msg_GetContentById (4009, @Language)
										ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
									END
								+ CASE WHEN @isLive = 1 THEN + ' ' + [dbo].f_Msg_GetContentById (4008, @Language) 
										ELSE '' 
									END
								+ ' - ' + dbo.f_Bet_GetNameByType(@betType, @Language) 
								+')'

					RETURN
				END

			-- Update new position taking if had changed
			IF EXISTS (	SELECT 1
						FROM AgentPositionTaking AS apt WITH (NOLOCK)
							INNER JOIN @TablePositionTaking AS tpt
								ON tpt.SportType	= apt.SportType
								AND tpt.BetType		= apt.BetType
								AND tpt.IsLive		= apt.IsLive
						WHERE apt.AgentId = @AgentId
							AND (apt.MaxUpperPositionTaking		<> tpt.MaxUpperPT
									OR apt.MaxGivenPositionTaking	<> tpt.MaxGivenPT
									OR apt.MinGivenPositionTaking	<> tpt.MinGivenPT ) )
				BEGIN
					-- write log before update
					SET @xml = (
						SELECT  
							SportType				AS '@s'
							,BetType				AS '@b'
							,IsLive					AS '@i'
							,MaxUpperPositionTaking	AS '@p'
							,MaxGivenPositionTaking	AS '@ma'
							,MinGivenPositionTaking	AS '@mi'
						FROM AgentPositionTaking WITH (NOLOCK)							
						WHERE AgentId = @AgentId	
						FOR XML PATH('z'), ROOT('r')
					)

					SET @logSPDataOld = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

					-- end write log before update

					INSERT INTO @TableChildAgent (AgentId)
					SELECT AgentId
					FROM AgentInfo WITH (NOLOCK)
					WHERE ParentId = @AgentId

					-- Edit Main Share Holder Position Taking
					IF @agentLevel = @MAINSHAREHOLDERLEVEL
						BEGIN
							-- If Max Given PT change
							IF EXISTS(	SELECT 1
										FROM AgentPositionTaking AS apt WITH (NOLOCK)
											INNER JOIN @TablePositionTaking AS tpt
												ON tpt.SportType	= apt.SportType
												AND tpt.BetType		= apt.BetType
												AND tpt.IsLive		= apt.IsLive
										WHERE apt.AgentId = @AgentId
											AND apt.MaxGivenPositionTaking	<> tpt.MaxGivenPT )
								BEGIN
									-- Check validate when update main share holder

									-- Max given position taking must be MinGivenPT < MaxGivenPT < @MAXSHAREHOLDERPT
									SELECT TOP(1) 
										@sportType	= SportType
										,@betType	= BetType
										,@isLive	= IsLive
									FROM @TablePositionTaking
									WHERE MaxGivenPT NOT BETWEEN MinGivenPT AND @MAXSHAREHOLDERPT

									IF @sportType IS NOT NULL 
										BEGIN
											SELECT 
												@ErrCode = 4004,
												@ErrMsg	= 
													CASE @Language
														WHEN 'en-US' THEN '% Downline must be equal to or less than 90%' 
														ELSE [dbo].f_Msg_GetContentById (4004, @Language)
													END + ' (' 
														+ CASE WHEN @sportType = 99 AND @betType = 9
																THEN [dbo].f_Msg_GetContentById (4009, @Language)
																ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
															END
														+ CASE WHEN @isLive = 1 THEN + ' ' + [dbo].f_Msg_GetContentById (4008, @Language) 
																ELSE '' 
															END
														+ ' - ' + dbo.f_Bet_GetNameByType(@betType, @Language) 
														+')'
										
											RETURN
										END

									-- Max given position taking must be greater or equal Max[Sum(PreK+MaxK)]
									SELECT TOP(1) 
										@sportType	= tpt.SportType
										,@betType	= tpt.BetType
										,@isLive	= tpt.IsLive
									FROM @TablePositionTaking AS tpt
										INNER JOIN (
											SELECT 
												AgentId
												,SportType
												,BetType
												,IsLive												
												,MaxUpperPositionTaking + MaxGivenPositionTaking AS SumMaxUpperAndGiven
											FROM AgentPositionTaking WITH (NOLOCK)
											WHERE AgentId IN ( SELECT AgentId FROM @TableChildAgent)
										) AS shareHolderTemp
											ON tpt.SportType	= shareHolderTemp.SportType
											AND tpt.BetType		= shareHolderTemp.BetType
											AND tpt.IsLive		= shareHolderTemp.IsLive
									WHERE tpt.MaxGivenPT < shareHolderTemp.SumMaxUpperAndGiven
									  
									IF @sportType IS NOT NULL 
										BEGIN
											SELECT 
												@ErrCode	= 4006,
												@ErrMsg		= 
													CASE @Language
														WHEN 'en-US' THEN 'Invalid % Downline range' 
														ELSE [dbo].f_Msg_GetContentById (4006, @Language)
													END + ' (' 
														+ CASE WHEN @sportType = 99 AND @betType = 9
																THEN [dbo].f_Msg_GetContentById (4009, @Language)
																ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
															END
														+ CASE WHEN @isLive = 1 THEN + ' ' + [dbo].f_Msg_GetContentById (4008, @Language) 
																ELSE '' 
															END
														+ ' - ' + dbo.f_Bet_GetNameByType(@betType, @Language) 
														+')'

											RETURN			
										END
									-- End check validate when update main share holder

									-- Begin update
									UPDATE apt
									SET apt.MaxGivenPositionTaking		= tpt.MaxGivenPT
										,apt.MaxUpperPositionTaking		= @MAXPT - tpt.MaxGivenPT 
									FROM AgentPositionTaking AS apt WITH (ROWLOCK,UPDLOCK)
										INNER JOIN @TablePositionTaking AS tpt
											ON apt.SportType	= tpt.SportType
											AND apt.BetType		= tpt.BetType
											AND apt.IsLive		= tpt.IsLive
									WHERE apt.AgentId = @AgentId
									-- End update
								END
							-- End update Max Given PT

							-- If Min Given PT change
							IF EXISTS (	SELECT 1
										FROM AgentPositionTaking AS apt WITH (NOLOCK)
											INNER JOIN @TablePositionTaking AS tpt
												ON tpt.SportType	= apt.SportType
												AND tpt.BetType		= apt.BetType
												AND tpt.IsLive		= apt.IsLive
										WHERE apt.AgentId = @AgentId
											AND apt.MinGivenPositionTaking	<> tpt.MinGivenPT )
								BEGIN
									-- If New Min Given PT greater than Current Min Givent PT
									IF EXISTS (	SELECT 1
												FROM AgentPositionTaking AS apt WITH (NOLOCK)
													INNER JOIN @TablePositionTaking AS tpt
														ON tpt.SportType	= apt.SportType
														AND tpt.BetType		= apt.BetType
														AND tpt.IsLive		= apt.IsLive
												WHERE apt.AgentId		= @AgentId
													AND tpt.MinGivenPT	> apt.MinGivenPositionTaking )
										BEGIN
											-- Don't need update direct member here because agent is main shareholder
																				
											-- Get all member in downline of agent
											DELETE @TableCust

											INSERT INTO @TableCust(CustId)
											SELECT ci.CustId 
											FROM 
												CustInfo AS ci WITH (NOLOCK)
												INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
											WHERE ai.AgentHId.IsDescendantOf(@agentHId) = 1
												AND ai.AgentId <> @AgentId
										
											-- Update PT all member Down < Min
											UPDATE cpt
											SET cpt.PositionTaking = tpt.MinGivenPT - sumDown.SumDown + cpt.PositionTaking 
											FROM CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)
												INNER JOIN @TablePositionTaking AS tpt
													ON cpt.SportType	= tpt.SportType
													AND cpt.BetType		= tpt.BetType
													AND cpt.IsLive		= tpt.IsLive
												INNER JOIN (
													SELECT 
														cpt.CustId
														,cpt.SportType
														,cpt.BetType
														,cpt.IsLive
														,SUM(cpt.PositionTaking) AS SumDown
													FROM 
														CustPositionTaking AS cpt WITH (NOLOCK)
														INNER JOIN @TableCust AS tempCust ON cpt.CustId	= tempCust.CustId
													GROUP BY 
														cpt.CustId
														,cpt.SportType
														,cpt.BetType
														,cpt.IsLive
												) AS sumDown
													ON cpt.SportType	= sumDown.SportType
													AND cpt.BetType		= sumDown.BetType
													AND cpt.IsLive		= sumDown.IsLive
													AND cpt.CustId		= sumDown.CustId
											WHERE cpt.AgentId	= @AgentId
												AND sumDown.SumDown < tpt.MinGivenPT
											-- End update PT all member Down < Min
										END
									-- End update Min Given PT greater than Current Min Given PT

									-- If New Min Given PT less than current Min Position Taking of agent
									IF EXISTS (	SELECT 1
												FROM AgentPositionTaking AS apt WITH (NOLOCK)
													INNER JOIN @TablePositionTaking AS tpt 
														ON apt.SportType	= tpt.SportType
														AND apt.BetType		= tpt.BetType
														AND apt.IsLive		= tpt.IsLive
												WHERE apt.AgentId = @AgentId
													AND tpt.MinGivenPT < apt.MinGivenPositionTaking )
										BEGIN

											-- Get all member in downline of agent
											DELETE @TableCust

											INSERT INTO @TableCust(CustId)
											SELECT ci.CustId 
											FROM 
												CustInfo AS ci WITH (NOLOCK)
												INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
											WHERE ai.AgentHId.IsDescendantOf(@agentHId) = 1
												AND ai.AgentId <> @AgentId													

											--DECLARE @TableCustAgent TABLE(CustId INT, AgentId INT,AgentLevel INT)

											WHILE EXISTS ( SELECT 1 FROM @TableCust )
												BEGIN
													-- Select current Cust Id
													SELECT TOP(1) @currentCustId = CustId
													FROM @TableCust

													DELETE @TableCustAgent

													INSERT INTO @TableCustAgent (
														CustId, 
														AgentId,
														AgentLevel)
													SELECT DISTINCT 
														cpt.CustId
														,ai.AgentId 
														,ai.AgentLevel
													FROM 
														CustPositionTaking AS cpt WITH (NOLOCK)	
														INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON cpt.AgentId = ai.AgentId																		
													WHERE 
														cpt.CustId = @currentCustId
														AND cpt.AgentId IN (	SELECT AgentId 
																				FROM AgentInfo WITH (NOLOCK)
																				WHERE ParentId = @AgentId )
													ORDER BY ai.AgentLevel

													SELECT TOP(1) @tempAgentId = AgentId 
													FROM @TableCustAgent

													DELETE @TableCustPositionTaking

													INSERT INTO @TableCustPositionTaking(
														CustId
														,SportType
														,BetType
														,IsLive
														,PositionTaking)
													SELECT 
														cpt.CustId
														,cpt.SportType
														,cpt.BetType
														,cpt.IsLive
														,CASE WHEN capt.MaxUpperPositionTaking > tpt.MinGivenPT - dcpt.SumOfPositionTaking
															THEN capt.MaxUpperPositionTaking
															ELSE tpt.MinGivenPT - dcpt.SumOfPositionTaking
														END
													FROM CustPositionTaking AS cpt WITH (NOLOCK)
														INNER JOIN @TablePositionTaking AS tpt
																ON cpt.SportType	= tpt.SportType
																AND cpt.BetType	= tpt.BetType
																AND cpt.IsLive		= tpt.IsLive
														INNER JOIN AgentPositionTaking AS capt WITH (NOLOCK)
															ON cpt.SportType	= capt.SportType
																AND cpt.BetType	= capt.BetType
																AND cpt.IsLive		= capt.IsLive
														INNER JOIN (
															SELECT 
																CustId
																,SportType
																,BetType
																,IsLive
																,SUM(PositionTaking) AS SumOfPositionTaking
															FROM 
																CustPositionTaking AS cpt WITH (NOLOCK)
																INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON cpt.AgentId	= ai.AgentId
															WHERE cpt.CustId		= @currentCustId
																AND ai.AgentLevel	> @agentLevel
															GROUP BY 
																CustId, 
																SportType, 
																BetType, 
																IsLive	
														) AS dcpt 
															ON 	cpt.SportType	= dcpt.SportType
																AND cpt.BetType = dcpt.BetType
																AND cpt.IsLive	= dcpt.IsLive
																AND cpt.CustId  = dcpt.CustId
													WHERE cpt.AgentId			= @AgentId
														AND cpt.CustId			= @currentCustId
														AND capt.AgentId		= @tempAgentId
														AND cpt.PositionTaking	> capt.MaxUpperPositionTaking

													UPDATE cpt	
													SET cpt.PositionTaking = tcpt.PositionTaking	
													FROM CustPositionTaking AS cpt WITH (ROWLOCK, UPDLOCK)
														INNER JOIN @TableCustPositionTaking AS tcpt
																ON cpt.SportType	= tcpt.SportType
																AND cpt.BetType	= tcpt.BetType
																AND cpt.IsLive		= tcpt.IsLive
													WHERE cpt.AgentId	= @AgentId
														AND cpt.CustId	= @currentCustId
														
													-- Remove cust id
													DELETE @TableCust 
													WHERE CustId = @currentCustId
												END
										END
									-- End if New Min Given PT less than current Min Position Taking of agent

									-- Begin update
									UPDATE apt
									SET apt.MinGivenPositionTaking	= tpt.MinGivenPT
									FROM AgentPositionTaking AS apt WITH (ROWLOCK, UPDLOCK)
										INNER JOIN @TablePositionTaking AS tpt
											ON apt.SportType	= tpt.SportType
											AND apt.BetType		= tpt.BetType
											AND apt.IsLive		= tpt.IsLive
									WHERE apt.AgentId = @AgentId
									-- End update
								END
							-- End update Min Given PT
						END
					-- End edit Main Share Holder Position Taking
					ELSE
					-- Begin edit Agent with level k ( k > 1)
						BEGIN
						
							--(1)-- Edit Max Upper PT
							IF EXISTS (	SELECT 1
										FROM AgentPositionTaking AS apt WITH (NOLOCK)
											INNER JOIN @TablePositionTaking AS tpt
												ON tpt.SportType	= apt.SportType
												AND tpt.BetType		= apt.BetType
												AND tpt.IsLive		= apt.IsLive
										WHERE apt.AgentId = @AgentId
											AND apt.MaxUpperPositionTaking	<> tpt.MaxUpperPT )
								BEGIN
									---- Check validate when update main share holder
									--SELECT TOP(1) @sportType	= tpt.SportType
									--				,@betType	= tpt.BetType
									--				,@isLive	= tpt.IsLive
									--FROM @TablePositionTaking AS tpt					
									--	INNER JOIN AgentPositionTaking AS papt WITH (NOLOCK)
									--		ON tpt.SportType	= papt.SportType
									--		AND tpt.BetType		= papt.BetType
									--		AND tpt.IsLive		= papt.IsLive									
									--WHERE papt.AgentId = @parentAgentId
									--	AND tpt.MaxUpperPT NOT BETWEEN CASE WHEN papt.MinGivenPositionTaking - tpt.MaxGivenPT > 0 
									--										THEN papt.MinGivenPositionTaking - tpt.MaxGivenPT
									--										ELSE 0
									--									END AND papt.MaxGivenPositionTaking - tpt.MaxGivenPT

									--IF @sportType IS NOT NULL 
									--	BEGIN
									--		SELECT 
									--			@ErrCode	= 4000,
									--			@ErrMsg		= 
									--				CASE @Language
									--					WHEN 'en-US' THEN 'Invalid taken share range' 
									--					ELSE [dbo].f_Msg_GetContentById (4000, @Language)
									--				END + ' (' 
									--					+ CASE WHEN @sportType = 99 AND @betType = 9
									--							THEN [dbo].f_Msg_GetContentById (4009, @Language)
									--							ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
									--						END
									--					+ CASE WHEN @isLive = 1 THEN + ' ' + [dbo].f_Msg_GetContentById (4008, @Language) 
									--							ELSE '' 
									--						END
									--					+ ' - ' + dbo.f_Bet_GetNameByType(@betType, @Language) 
									--					+')'

									--		RETURN			
									--	END

									-- Update New Max Upper PT less than Current Max Upper PT of agent
									IF EXISTS (	SELECT 1
												FROM AgentPositionTaking AS apt WITH (NOLOCK)
													INNER JOIN @TablePositionTaking AS tpt
														ON tpt.SportType	= apt.SportType
														AND tpt.BetType		= apt.BetType
														AND tpt.IsLive		= apt.IsLive
												WHERE apt.AgentId		= @AgentId
													AND tpt.MaxUpperPT	< apt.MaxUpperPositionTaking )
										BEGIN
											-- Reset @TableCust
											DELETE @TableCust

											-- Get all direct member
											INSERT INTO @TableCust (CustId)
											SELECT CustId
											FROM CustInfo WITH (NOLOCK)
											WHERE AgentId = @AgentId

											-- Reset @TableCustPosistionTaking
											DELETE @TableCustPositionTaking

											-- Get all member break rule dirrect member of current agent
											INSERT INTO @TableCustPositionTaking (
												CustId
												,SportType
												,BetType
												,IsLive
												,PositionTaking)
											SELECT
												cpt.CustId
												,cpt.SportType
												,cpt.BetType
												,cpt.IsLive
												,cpt.PositionTaking 
											FROM CustPositionTaking AS cpt WITH (NOLOCK)	
												INNER JOIN @TablePositionTaking AS tpt
													ON tpt.SportType	= cpt.SportType
													AND tpt.BetType		= cpt.BetType
													AND tpt.IsLive		= cpt.IsLive
												INNER JOIN @TableCust AS tc ON cpt.CustId = tc.CustId
											WHERE cpt.AgentId = @parentAgentId
												AND cpt.PositionTaking > tpt.MaxUpperPT

											-- Get member break rule of agent level k
											IF @isLastAgent = 0
												BEGIN
													-- Reset @TableCust
													DELETE @TableCust

													-- Get all indirect member
													INSERT INTO @TableCust (CustId)
													SELECT ci.CustId
													FROM 
														CustInfo AS ci WITH (NOLOCK)
														INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
													WHERE ai.AgentId <> @AgentId
														AND ai.AgentHId.IsDescendantOf(@agentHId) = 1
																		
													-- Get all indirect member break rule of agent 
													INSERT INTO @TableCustPositionTaking (
														CustId
														,SportType
														,BetType
														,IsLive
														,PositionTaking)
													SELECT
														cpt.CustId
														,cpt.SportType
														,cpt.BetType
														,cpt.IsLive
														,cpt.PositionTaking 
													FROM CustPositionTaking AS cpt WITH (NOLOCK)	
														INNER JOIN @TablePositionTaking AS tpt
															ON tpt.SportType	= cpt.SportType
															AND tpt.BetType		= cpt.BetType
															AND tpt.IsLive		= cpt.IsLive
														INNER JOIN @TableCust AS tc ON cpt.CustId = tc.CustId
														INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
															ON apt.SportType	= cpt.SportType
															AND apt.BetType		= cpt.BetType
															AND apt.IsLive		= cpt.IsLive
													WHERE cpt.AgentId	= @parentAgentId
														AND apt.AgentId = @AgentId
														AND cpt.PositionTaking	> tpt.MaxUpperPT 
														AND cpt.PositionTaking	<= apt.MaxUpperPositionTaking
													-- End get all indirect member break rule of agent
												END	
											-- Get member break rule of agent level k
										
											-- Update member pt
											UPDATE cpt
											SET cpt.PositionTaking = 
												CASE 
													WHEN tpt.MaxUpperPT > papt.MinGivenPositionTaking - sumDown.SumDown
														THEN tpt.MaxUpperPT
													ELSE papt.MinGivenPositionTaking - sumDown.SumDown
												END
											FROM 
												CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)
												INNER JOIN @TablePositionTaking AS tpt
													ON cpt.SportType	= tpt.SportType
													AND cpt.BetType		= tpt.BetType
													AND cpt.IsLive		= tpt.IsLive
												INNER JOIN (
													SELECT 
														cpt.CustId
														,cpt.SportType
														,cpt.BetType
														,cpt.IsLive
														,SUM(cpt.PositionTaking) AS SumDown
													FROM 
														CustPositionTaking AS cpt WITH (NOLOCK)
														INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON cpt.AgentId		= ai.AgentId
														INNER JOIN @TableCustPositionTaking AS tcpt
															ON cpt.SportType	= tcpt.SportType
															AND cpt.BetType		= tcpt.BetType
															AND cpt.IsLive		= tcpt.IsLive
															AND cpt.CustId		= tcpt.CustId
													WHERE ai.AgentLevel > @agentParentLevel
													GROUP BY 
														cpt.CustId
														,cpt.SportType
														,cpt.BetType
														,cpt.IsLive
												) AS sumDown	
													ON cpt.SportType	= sumDown.SportType
													AND cpt.BetType		= sumDown.BetType
													AND cpt.IsLive		= sumDown.IsLive		
													AND cpt.CustId		= sumDown.CustId	
												INNER JOIN AgentPositionTaking AS papt WITH (NOLOCK)
													ON cpt.SportType	= papt.SportType
													AND cpt.BetType		= papt.BetType
													AND cpt.IsLive		= papt.IsLive
											WHERE papt.AgentId	= @parentAgentId	
												AND cpt.AgentId	= @parentAgentId
										
											
											--(Update Member When Down)-- Edit Position Taking of member for mem less than current mem pt
											WHILE EXISTS ( SELECT 1 FROM @TableCustPositionTaking )
												BEGIN
													DELETE @TableTempAgent

													INSERT INTO @TableTempAgent(AgentId)
													SELECT AgentId 
													FROM AgentInfo WITH (NOLOCK) 
													WHERE @agentParentHId.IsDescendantOf(AgentHId) = 1

													-- Edit Position Taking of member for mem less than current mem pt
													SELECT TOP(1) @currentCustId = CustId
													FROM @TableCustPositionTaking
												
													DELETE @TableStackPositionTaking

													INSERT INTO @TableStackPositionTaking (
														AgentId
														,AgentLevel
														,SportType
														,BetType
														,IsLive
														,PT
														,MinPT)
													SELECT 
														apt.AgentId
														,ai.AgentLevel
														,apt.SportType
														,apt.BetType
														,apt.IsLive
														,cpt.PositionTaking
														,apt.MinGivenPositionTaking 	
													FROM 
														AgentPositionTaking AS apt WITH (NOLOCK)
														INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON apt.AgentId = ai.AgentId
														INNER JOIN CustPositionTaking AS cpt WITH (NOLOCK)
															ON apt.SportType	= cpt.SportType
															AND apt.BetType		= cpt.BetType
															AND apt.IsLive		= cpt.IsLive
															AND apt.AgentId		= cpt.AgentId
														INNER JOIN @TableCustPositionTaking AS tcpt
															ON cpt.SportType	= tcpt.SportType
															AND cpt.BetType		= tcpt.BetType
															AND cpt.IsLive		= tcpt.IsLive
															AND cpt.CustId		= tcpt.CustId
													WHERE ai.AgentId IN (SELECT AgentId FROM @TableTempAgent)
														AND cpt.CustId = @currentCustId

													WHILE EXISTS ( SELECT 1 FROM @TableTempAgent )
														BEGIN						
															SELECT TOP(1) @tempAgentId = AgentId
															FROM @TableTempAgent

															SELECT @tempLevel =	AgentLevel
															FROM AgentInfo WITH (NOLOCK)
															WHERE AgentId = @tempAgentId

															UPDATE tspt
															SET	tspt.SumDownPT = temp.Sum
															FROM @TableStackPositionTaking AS tspt
																INNER JOIN (		
																	SELECT 
																		tcpt.SportType
																		,tcpt.BetType
																		,tcpt.IsLive
																		,SUM(tcpt.PositionTaking) AS Sum
																	FROM CustPositionTaking AS tcpt WITH (NOLOCK)
																		INNER JOIN AgentInfo AS tai WITH (NOLOCK)
																			ON tcpt.AgentId		= tai.AgentId
																	WHERE tcpt.CustId = @currentCustId		
																		AND tai.AgentLevel >= @tempLevel
																	GROUP BY 
																		tcpt.SportType
																		,tcpt.BetType
																		,tcpt.IsLive
																) AS temp
																	ON tspt.SportType	= temp.SportType
																	AND tspt.BetType	= temp.BetType
																	AND tspt.IsLive		= temp.IsLive
															WHERE tspt.AgentLevel		= @tempLevel

															DELETE @TableTempAgent 
															WHERE AgentId = @tempAgentId 
														END
													
													UPDATE cpt
													SET cpt.PositionTaking = tempUpdate.MinPT - tempUpdate.SumDownPT + tempUpdate.PT
													FROM CustPositionTaking AS cpt WITH (ROWLOCK, UPDLOCK)
														INNER JOIN (
															SELECT 
																tspt.AgentId
																,tspt.AgentLevel
																,tspt.SportType
																,tspt.BetType
																,tspt.IsLive
																,tspt.PT
																,tspt.MinPT
																,tspt.SumDownPT
															FROM @TableStackPositionTaking AS tspt
																INNER JOIN (
																	SELECT	
																		MAX(tspt.AgentLevel) AS AgentLevel
																		,tspt.SportType
																		,tspt.BetType
																		,tspt.IsLive 
																	FROM @TableStackPositionTaking AS tspt
																	WHERE tspt.SumDownPT < tspt.MinPT
																	GROUP BY 
																		tspt.SportType
																		,tspt.BetType
																		,tspt.IsLive
																) AS temp
																	ON tspt.SportType	= temp.SportType
																	AND tspt.BetType	= temp.BetType
																	AND tspt.IsLive		= temp.IsLive
																	AND tspt.AgentLevel	= temp.AgentLevel
														) AS tempUpdate
															ON cpt.SportType	= tempUpdate.SportType
															AND cpt.BetType		= tempUpdate.BetType
															AND cpt.IsLive		= tempUpdate.IsLive
															AND cpt.AgentId		= tempUpdate.AgentId
													WHERE cpt.CustId = @currentCustId

													-- Remove cust
													DELETE @TableCustPositionTaking 
													WHERE CustId = @currentCustId
												END									
											--(Update Member When Down)-- End edit Position Taking of member for mem less than current mem pt
										
										END
									-- End update New Max Upper PT less than Current Max Upper PT of agent

									-- Update Max Upper PT
									UPDATE apt
									SET apt.MaxUpperPositionTaking	= tpt.MaxUpperPT
									FROM AgentPositionTaking AS apt WITH (ROWLOCK, UPDLOCK)
										INNER JOIN @TablePositionTaking AS tpt
											ON apt.SportType	= tpt.SportType
											AND apt.BetType		= tpt.BetType
											AND apt.IsLive		= tpt.IsLive
									WHERE apt.AgentId = @AgentId

								END
							--(1)-- End edit Max Upper PT	

							--(3)-- Edit Min Given PT
							IF EXISTS (	SELECT 1
										FROM AgentPositionTaking AS apt WITH (NOLOCK)
											INNER JOIN @TablePositionTaking AS tpt
												ON tpt.SportType	= apt.SportType
												AND tpt.BetType		= apt.BetType
												AND tpt.IsLive		= apt.IsLive
										WHERE apt.AgentId = @AgentId
											AND apt.MinGivenPositionTaking <> tpt.MinGivenPT )
								BEGIN
									-- Update if min greater
									IF EXISTS(	SELECT 1
												FROM AgentPositionTaking AS apt WITH (NOLOCK)
													INNER JOIN @TablePositionTaking AS tpt
														ON tpt.SportType	= apt.SportType
														AND tpt.BetType		= apt.BetType
														AND tpt.IsLive		= apt.IsLive
												WHERE apt.AgentId = @AgentId
													AND tpt.MinGivenPT > apt.MinGivenPositionTaking )
										BEGIN
											-- Update PT of all direct member of agent
											DELETE @TableCust

											INSERT INTO @TableCust (CustId)
											SELECT CustId
											FROM CustInfo WITH (NOLOCK)
											WHERE AgentId = @AgentId
									
											DELETE @TableCustPositionTaking

											INSERT INTO @TableCustPositionTaking(
												 CustId
												,SportType
												,BetType
												,IsLive
												,PositionTaking)
											SELECT
												cpt.CustId 
												,cpt.SportType
												,cpt.BetType
												,cpt.IsLive
												,tpt.MinGivenPT
											FROM CustPositionTaking AS cpt WITH (NOLOCK)
												INNER JOIN @TableCust AS tc ON cpt.CustId		= tc.CustId
												INNER JOIN @TablePositionTaking AS tpt
													ON cpt.SportType	= tpt.SportType
													AND cpt.BetType		= tpt.BetType
													AND cpt.IsLive		= tpt.IsLive
											WHERE cpt.AgentId			= @AgentId
												AND cpt.PositionTaking	< tpt.MinGivenPT
											
											---- update direct member	
											----UPDATE cpt
											----SET	cpt.PositionTaking = tcpt.PositionTaking
											----FROM CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)																																
											----	INNER JOIN @TableCustPositionTaking AS tcpt
											----		ON cpt.SportType	= tcpt.SportType
											----		AND cpt.BetType		= tcpt.BetType
											----		AND cpt.IsLive		= tcpt.IsLive
											----		AND cpt.CustId		= tcpt.CustId
											----WHERE cpt.AgentId	= @AgentId
													
											-- End update direct member
											--(Update Member PT Greater)-- 	dang check chua xog	
											WHILE EXISTS ( SELECT 1 FROM @TableCustPositionTaking ) 
												BEGIN

													SELECT TOP(1) @currentCustId = CustId
													FROM @TableCustPositionTaking

													-- Update member position taking when member position taking greater
													DELETE @TableTempPositionTaking

													INSERT INTO @TableTempPositionTaking(
														AgentId
														,AgentLevel
														,SportType
														,BetType
														,IsLive
														,PT
														,Preset)
													SELECT	
														cpt.AgentId
														,tai.AgentLevel
														,cpt.SportType
														,cpt.BetType
														,cpt.IsLive	
														,cpt.PositionTaking
														,apt.MaxUpperPositionTaking
													FROM CustPositionTaking AS cpt WITH (NOLOCK)
														INNER JOIN @TableCustPositionTaking AS tcpt 
															ON cpt.SportType	= tcpt.SportType
															AND cpt.BetType		= tcpt.BetType
															AND cpt.IsLive		= tcpt.IsLive	
														INNER JOIN AgentInfo AS tai WITH (NOLOCK)
															ON cpt.AgentId	= tai.AgentId
														INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
															ON cpt.SportType	= apt.SportType
															AND cpt.BetType		= apt.BetType
															AND cpt.IsLive		= apt.IsLive
														INNER JOIN AgentInfo AS ai WITH (NOLOCK)
															ON apt.AgentId		= ai.AgentId
															AND ai.ParentId		= cpt.AgentId
															AND ai.AgentId IN (	SELECT DISTINCT AgentId 
																				FROM CustPositionTaking WITH (NOLOCK)
																				WHERE CustId = @currentCustId)
													WHERE cpt.CustId = @currentCustId
														AND apt.MaxUpperPositionTaking < cpt.PositionTaking
														AND tai.AgentLevel < @agentLevel

													DELETE @TableUpdateCustPositionTaking

													INSERT INTO @TableUpdateCustPositionTaking(
														AgentId
														,SportType
														,BetType
														,IsLive
														,PT
														,Preset
														,IsDeleted)
													SELECT DISTINCT
														ccpt.AgentId
														,ccpt.SportType
														,ccpt.BetType
														,ccpt.IsLive
														,ISNULL(ccpt.PositionTaking, 0)
														,ISNULL(ttpt.Preset, 0)
														,0
													FROM 
														CustPositionTaking AS ccpt WITH (NOLOCK)
														INNER JOIN @TableTempPositionTaking AS ttpt
															ON ccpt.SportType		= ttpt.SportType
															AND ccpt.BetType		= ttpt.BetType
															AND ccpt.IsLive			= ttpt.IsLive
															AND ccpt.AgentId		= ttpt.AgentId
														INNER JOIN (
															SELECT 
																MAX(AgentLevel) AS AgentLevel
																,SportType
																,BetType
																,IsLive
															FROM @TableTempPositionTaking
															GROUP BY 
																SportType
																,BetType
																,IsLive
														) AS temp
															ON ttpt.SportType	= temp.SportType
															AND ttpt.BetType	= temp.BetType
															AND ttpt.IsLive		= temp.IsLive
															AND ttpt.AgentLevel	= temp.AgentLevel
													WHERE ccpt.CustId = @currentCustId

													UPDATE tupt 
													SET tupt.Result = tpt.PositionTaking - cpt.PositionTaking
													FROM @TableUpdateCustPositionTaking AS tupt
														INNER JOIN @TableCustPositionTaking AS tpt
															ON tupt.SportType	= tpt.SportType
															AND tupt.BetType	= tpt.BetType
															AND tupt.IsLive		= tpt.IsLive
														INNER JOIN CustPositionTaking AS cpt WITH (NOLOCK)
															ON tupt.SportType	= cpt.SportType
															AND tupt.BetType	= cpt.BetType
															AND tupt.IsLive		= cpt.IsLive
													WHERE tpt.PositionTaking > cpt.PositionTaking
														AND cpt.CustId	= @currentCustId
														AND cpt.AgentId	= @AgentId

													WHILE EXISTS ( SELECT 1 FROM @TableUpdateCustPositionTaking WHERE Result > 0 )
														BEGIN
															UPDATE cpt
															SET cpt.PositionTaking	= 
																CASE 
																	WHEN tupt.Preset > tupt.PT - tupt.Result THEN tupt.Preset
																	ELSE tupt.PT - tupt.Result
																END
															FROM CustPositionTaking AS cpt WITH (ROWLOCK, UPDLOCK)
																INNER JOIN @TableUpdateCustPositionTaking AS tupt
																	ON cpt.SportType	= tupt.SportType
																	AND cpt.BetType		= tupt.BetType
																	AND cpt.IsLive		= tupt.IsLive
																	AND cpt.AgentId		= tupt.AgentId
															WHERE cpt.CustId = @currentCustId
									
															UPDATE tupt
															SET tupt.Result	= tupt.Result - (tupt.PT - cpt.PositionTaking)
																,tupt.IsDeleted = 1
															FROM @TableUpdateCustPositionTaking AS tupt
																INNER JOIN CustPositionTaking AS cpt WITH (NOLOCK)
																	ON tupt.SportType	= cpt.SportType
																	AND tupt.BetType	= cpt.BetType
																	AND tupt.IsLive		= cpt.IsLive
																	AND tupt.AgentId	= cpt.AgentId
															WHERE cpt.CustId = @currentCustId	

															IF EXISTS ( SELECT 1 FROM @TableUpdateCustPositionTaking WHERE Result > 0 )
																BEGIN
																	DELETE @TableTempPositionTaking

																	INSERT INTO @TableTempPositionTaking(
																		AgentId
																		,AgentLevel
																		,SportType
																		,BetType
																		,IsLive
																		,PT
																		,Preset)
																	SELECT	
																		cpt.AgentId
																		,tai.AgentLevel
																		,cpt.SportType
																		,cpt.BetType
																		,cpt.IsLive	
																		,cpt.PositionTaking
																		,apt.MaxUpperPositionTaking
																	FROM CustPositionTaking AS cpt WITH (NOLOCK)	
																		INNER JOIN @TableCustPositionTaking AS tcpt 
																			ON cpt.SportType	= tcpt.SportType
																			AND cpt.BetType		= tcpt.BetType
																			AND cpt.IsLive		= tcpt.IsLive	
																		INNER JOIN AgentInfo AS tai WITH (NOLOCK)
																			ON cpt.AgentId	= tai.AgentId
																		INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
																			ON cpt.SportType	= apt.SportType
																			AND cpt.BetType		= apt.BetType
																			AND cpt.IsLive		= apt.IsLive
																		INNER JOIN AgentInfo AS ai WITH (NOLOCK)
																			ON apt.AgentId		= ai.AgentId
																			AND ai.ParentId		= cpt.AgentId
																			AND ai.AgentId IN (SELECT DISTINCT AgentId FROM CustPositionTaking WHERE CustId = @currentCustId) 		 	
																	WHERE cpt.CustId = @currentCustId
																		AND apt.MaxUpperPositionTaking < cpt.PositionTaking
																		AND tai.AgentLevel < @agentLevel

																	INSERT INTO @TableUpdateCustPositionTaking (
																		AgentId
																		,SportType
																		,BetType
																		,IsLive
																		,PT
																		,Preset
																		,IsDeleted)
																	SELECT DISTINCT
																		ccpt.AgentId
																		,ccpt.SportType
																		,ccpt.BetType
																		,ccpt.IsLive
																		,ISNULL(ccpt.PositionTaking, 0)
																		,ISNULL(ttpt.Preset, 0)
																		,0
																	FROM CustPositionTaking AS ccpt WITH (NOLOCK)
																		INNER JOIN @TableTempPositionTaking AS ttpt
																			ON ccpt.SportType	= ttpt.SportType
																			AND ccpt.BetType	= ttpt.BetType
																			AND ccpt.IsLive		= ttpt.IsLive
																			AND ccpt.AgentId	= ttpt.AgentId
																		INNER JOIN (
																			SELECT 
																				MAX(AgentLevel) AS AgentLevel
																				,SportType
																				,BetType
																				,IsLive
																			FROM @TableTempPositionTaking
																			GROUP BY 
																				SportType
																				,BetType
																				,IsLive
																		) AS temp
																			ON ttpt.SportType	= temp.SportType
																			AND ttpt.BetType	= temp.BetType
																			AND ttpt.IsLive		= temp.IsLive
																			AND ttpt.AgentLevel	= temp.AgentLevel
																	WHERE ccpt.CustId = @currentCustId

																	UPDATE tupt
																	SET tupt.Result	= dtupt.Result
																	FROM @TableUpdateCustPositionTaking AS tupt
																		INNER JOIN @TableUpdateCustPositionTaking AS dtupt
																			ON tupt.SportType	= dtupt.SportType
																			AND tupt.BetType	= dtupt.BetType
																			AND tupt.IsLive		= dtupt.IsLive
																	WHERE dtupt.IsDeleted	= 1
																		AND tupt.IsDeleted	= 0

																	DELETE @TableUpdateCustPositionTaking 
																	WHERE IsDeleted = 1
																END
															ELSE
																BEGIN
																	DELETE @TableUpdateCustPositionTaking
																END
													END
													-- End update member position taking when member position taking greater
													-- update direct member	
													UPDATE cpt
													SET	cpt.PositionTaking = tcpt.PositionTaking
													FROM CustPositionTaking AS cpt WITH (ROWLOCK, UPDLOCK)
														INNER JOIN @TableCustPositionTaking AS tcpt
															ON cpt.SportType	= tcpt.SportType
															AND cpt.BetType		= tcpt.BetType
															AND cpt.IsLive		= tcpt.IsLive
															AND cpt.CustId		= tcpt.CustId
													WHERE cpt.AgentId	= @AgentId	
														AND cpt.CustId	= @currentCustId

													DELETE @TableCustPositionTaking 
													WHERE CustId = @currentCustId
												END
												--(Update Member PT Greater)-- 	
												 
												-- End update Position Taking of direct member
											END
									-- Update if min greater

									-- Check for update Min Given PT of agent level k
									IF @isLastAgent = 0
										BEGIN
											-- If New Min Given PT greater than current Min Position Taking of agent
											IF EXISTS (	SELECT 1
														FROM AgentPositionTaking AS apt WITH (NOLOCK)
															INNER JOIN @TablePositionTaking AS tpt 
																ON apt.SportType	= tpt.SportType
																AND apt.BetType		= tpt.BetType
																AND apt.IsLive		= tpt.IsLive
														WHERE apt.AgentId = @AgentId
															AND tpt.MinGivenPT > apt.MinGivenPositionTaking )
												BEGIN
													-- The same with update Min Given PT of Main ShareHolder
													-- Get all member in downline of agent
													DELETE @TableCust

													INSERT INTO @TableCust(CustId)
													SELECT ci.CustId 
													FROM 
														CustInfo AS ci WITH (NOLOCK)
														INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
													WHERE ai.AgentHId.IsDescendantOf(@agentHId) = 1
														AND ai.AgentId <> @AgentId
										
													WHILE EXISTS ( SELECT 1 FROM @TableCust )
														BEGIN
															-- Select current Cust Id
															SELECT TOP(1) @currentCustId = CustId
															FROM @TableCust

															DELETE @TableCustPositionTaking

															INSERT INTO @TableCustPositionTaking (
																SportType
																,BetType
																,IsLive
																,PositionTaking)
															SELECT
																cpt.SportType
																,cpt.BetType
																,cpt.IsLive
																,tpt.MinGivenPT - dcpt.SumOfPositionTaking + cpt.PositionTaking
															FROM CustPositionTaking AS cpt WITH (ROWLOCK, UPDLOCK)
																INNER JOIN @TablePositionTaking AS tpt
																	ON cpt.SportType	= tpt.SportType
																	AND cpt.BetType		= tpt.BetType
																	AND cpt.IsLive		= tpt.IsLive
																INNER JOIN (
																	SELECT 
																		CustId
																		,SportType
																		,BetType
																		,IsLive
																		,SUM(PositionTaking) AS SumOfPositionTaking
																	FROM 
																		CustPositionTaking AS cpt WITH (NOLOCK)	
																		INNER JOIN AgentInfo AS ai WITH (NOLOCK)
																			ON cpt.AgentId	= ai.AgentId															
																	WHERE cpt.CustId		= @currentCustId
																		AND ai.AgentLevel	>= @agentLevel		
																	GROUP BY 
																		CustId, 
																		SportType, 
																		BetType, 
																		IsLive	
																) AS dcpt 
																	ON 	cpt.SportType	= dcpt.SportType
																		AND cpt.BetType = dcpt.BetType
																		AND cpt.IsLive	= dcpt.IsLive	
																		AND cpt.CustId	= dcpt.CustId
															WHERE dcpt.SumOfPositionTaking < tpt.MinGivenPT
																AND cpt.AgentId	= @AgentId
																AND cpt.CustId	= @currentCustId

															-- Update member position taking when member position taking greater																								
															DELETE @TableTempPositionTaking

															INSERT INTO @TableTempPositionTaking(
																AgentId
																,AgentLevel
																,SportType
																,BetType
																,IsLive
																,PT
																,Preset)
															SELECT	
																cpt.AgentId
																,tai.AgentLevel
																,cpt.SportType
																,cpt.BetType
																,cpt.IsLive	
																,cpt.PositionTaking
																,apt.MaxUpperPositionTaking
															FROM CustPositionTaking AS cpt WITH (NOLOCK)
																INNER JOIN @TableCustPositionTaking AS tcpt 
																	ON cpt.SportType	= tcpt.SportType
																	AND cpt.BetType		= tcpt.BetType
																	AND cpt.IsLive		= tcpt.IsLive	
																INNER JOIN AgentInfo AS tai WITH (NOLOCK)
																	ON cpt.AgentId	= tai.AgentId
																INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
																	ON cpt.SportType	= apt.SportType
																	AND cpt.BetType		= apt.BetType
																	AND cpt.IsLive		= apt.IsLive
																INNER JOIN AgentInfo AS ai WITH (NOLOCK)
																	ON apt.AgentId		= ai.AgentId
																	AND ai.ParentId		= cpt.AgentId
																	AND ai.AgentId IN (SELECT DISTINCT AgentId FROM CustPositionTaking WHERE CustId = @currentCustId) 		 	
															WHERE cpt.CustId = @currentCustId
																AND apt.MaxUpperPositionTaking < cpt.PositionTaking
																AND tai.AgentLevel < @agentLevel 

															DELETE @TableUpdateCustPositionTaking

															INSERT INTO @TableUpdateCustPositionTaking(
																AgentId
																,SportType
																,BetType
																,IsLive
																,PT
																,Preset
																,IsDeleted)
															SELECT DISTINCT
																ccpt.AgentId
																,ccpt.SportType
																,ccpt.BetType
																,ccpt.IsLive
																,ISNULL(ccpt.PositionTaking, 0)
																,ISNULL(ttpt.Preset, 0)
																,0
															FROM CustPositionTaking AS ccpt WITH (NOLOCK)
																INNER JOIN @TableTempPositionTaking AS ttpt
																	ON ccpt.SportType	= ttpt.SportType
																	AND ccpt.BetType	= ttpt.BetType
																	AND ccpt.IsLive		= ttpt.IsLive
																	AND ccpt.AgentId	= ttpt.AgentId
																INNER JOIN (
																	SELECT 
																		MAX(AgentLevel) AS AgentLevel
																		,SportType
																		,BetType
																		,IsLive
																	FROM @TableTempPositionTaking 
																	GROUP BY 
																		SportType
																		,BetType
																		,IsLive
																) AS temp
																	ON ttpt.SportType	= temp.SportType
																	AND ttpt.BetType	= temp.BetType
																	AND ttpt.IsLive		= temp.IsLive
																	AND ttpt.AgentLevel	= temp.AgentLevel
															WHERE ccpt.CustId = @currentCustId
												
															UPDATE tupt 
															SET tupt.Result = tpt.PositionTaking - cpt.PositionTaking
															FROM @TableUpdateCustPositionTaking AS tupt
																INNER JOIN @TableCustPositionTaking AS tpt
																	ON tupt.SportType	= tpt.SportType
																	AND tupt.BetType	= tpt.BetType
																	AND tupt.IsLive		= tpt.IsLive
																INNER JOIN CustPositionTaking AS cpt WITH (NOLOCK)
																	ON tupt.SportType	= cpt.SportType
																	AND tupt.BetType	= cpt.BetType
																	AND tupt.IsLive		= cpt.IsLive
															WHERE tpt.PositionTaking > cpt.PositionTaking
																AND cpt.CustId	= @currentCustId
																AND cpt.AgentId	= @AgentId

															WHILE EXISTS ( SELECT 1 FROM @TableUpdateCustPositionTaking WHERE Result > 0 )
																BEGIN
																	UPDATE cpt
																	SET cpt.PositionTaking	= 
																		CASE 
																			WHEN tupt.Preset > tupt.PT - tupt.Result
																				THEN tupt.Preset
																			ELSE tupt.PT - tupt.Result
																		END
																	FROM CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)
																		INNER JOIN @TableUpdateCustPositionTaking AS tupt
																			ON cpt.SportType	= tupt.SportType
																			AND cpt.BetType		= tupt.BetType
																			AND cpt.IsLive		= tupt.IsLive
																			AND cpt.AgentId		= tupt.AgentId
																	WHERE cpt.CustId = @currentCustId

																	UPDATE tupt
																	SET 
																		tupt.Result = tupt.Result - (tupt.PT - cpt.PositionTaking)
																		,tupt.IsDeleted = 1
																	FROM @TableUpdateCustPositionTaking AS tupt
																		INNER JOIN CustPositionTaking AS cpt WITH (NOLOCK)
																			ON tupt.SportType	= cpt.SportType
																			AND tupt.BetType	= cpt.BetType
																			AND tupt.IsLive		= cpt.IsLive
																			AND tupt.AgentId	= cpt.AgentId
																	WHERE cpt.CustId = @currentCustId	

																	IF EXISTS ( SELECT 1 FROM @TableUpdateCustPositionTaking WHERE Result > 0 )
																		BEGIN
																			DELETE @TableTempPositionTaking

																			INSERT INTO @TableTempPositionTaking(
																				AgentId
																				,AgentLevel
																				,SportType
																				,BetType
																				,IsLive
																				,PT
																				,Preset)
																			SELECT	
																				cpt.AgentId
																				,tai.AgentLevel
																				,cpt.SportType
																				,cpt.BetType
																				,cpt.IsLive	
																				,cpt.PositionTaking
																				,apt.MaxUpperPositionTaking
																			FROM CustPositionTaking AS cpt WITH (NOLOCK)	
																				INNER JOIN @TableCustPositionTaking AS tcpt 
																					ON cpt.SportType	= tcpt.SportType
																					AND cpt.BetType		= tcpt.BetType
																					AND cpt.IsLive		= tcpt.IsLive	
																				INNER JOIN AgentInfo AS tai WITH (NOLOCK)
																					ON cpt.AgentId	= tai.AgentId
																				INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
																					ON cpt.SportType	= apt.SportType
																					AND cpt.BetType		= apt.BetType
																					AND cpt.IsLive		= apt.IsLive
																				INNER JOIN AgentInfo AS ai WITH (NOLOCK)
																					ON apt.AgentId		= ai.AgentId
																					AND ai.ParentId		= cpt.AgentId
																					AND ai.AgentId IN (SELECT DISTINCT AgentId FROM CustPositionTaking WHERE CustId = @currentCustId) 		 	
																			WHERE cpt.CustId = @currentCustId
																				AND apt.MaxUpperPositionTaking < cpt.PositionTaking
																				AND tai.AgentLevel < @agentLevel

																			INSERT INTO @TableUpdateCustPositionTaking (
																				AgentId
																				,SportType
																				,BetType
																				,IsLive
																				,PT
																				,Preset
																				,IsDeleted)
																			SELECT DISTINCT
																				ccpt.AgentId
																				,ccpt.SportType
																				,ccpt.BetType
																				,ccpt.IsLive
																				,ISNULL(ccpt.PositionTaking, 0)
																				,ISNULL(ttpt.Preset, 0)
																				,0
																			FROM CustPositionTaking AS ccpt WITH (NOLOCK)
																				INNER JOIN @TableTempPositionTaking AS ttpt
																					ON ccpt.SportType		= ttpt.SportType
																					AND ccpt.BetType		= ttpt.BetType
																					AND ccpt.IsLive			= ttpt.IsLive
																					AND ccpt.AgentId		= ttpt.AgentId
																				INNER JOIN (
																					SELECT 
																						MAX(AgentLevel) AS AgentLevel
																						,SportType
																						,BetType
																						,IsLive
																					FROM @TableTempPositionTaking
																					GROUP BY 
																						SportType
																						,BetType
																						,IsLive
																				) AS temp
																					ON ttpt.SportType	= temp.SportType
																					AND ttpt.BetType	= temp.BetType
																					AND ttpt.IsLive		= temp.IsLive
																					AND ttpt.AgentLevel	= temp.AgentLevel
																			WHERE ccpt.CustId = @currentCustId

																			UPDATE tupt
																			SET tupt.Result = dtupt.Result
																			FROM @TableUpdateCustPositionTaking AS tupt
																				INNER JOIN @TableUpdateCustPositionTaking AS dtupt
																					ON tupt.SportType	= dtupt.SportType
																					AND tupt.BetType	= dtupt.BetType
																					AND tupt.IsLive		= dtupt.IsLive
																			WHERE dtupt.IsDeleted	= 1
																				AND tupt.IsDeleted	= 0

																			DELETE @TableUpdateCustPositionTaking 
																			WHERE IsDeleted = 1
																		END
																	ELSE
																		BEGIN
																			DELETE @TableUpdateCustPositionTaking		
																		END
																END
															-- End update member position taking when member position taking greater

															UPDATE cpt
															SET	cpt.PositionTaking = tcpt.PositionTaking
															FROM CustPositionTaking AS cpt WITH (ROWLOCK, UPDLOCK)
																INNER JOIN @TableCustPositionTaking AS tcpt
																	ON cpt.SportType	= tcpt.SportType
																	AND cpt.BetType		= tcpt.BetType
																	AND cpt.IsLive		= tcpt.IsLive
															WHERE cpt.CustId		= @currentCustId
																AND cpt.AgentId		= @AgentId
								
															-- Remove cust id
															DELETE @TableCust 
															WHERE CustId = @currentCustId
														END
													 -- End the same with update Min Given PT of Main ShareHolder
												END
											-- End if New Min Given PT greater than current Min Position Taking of agent
										
											-- If New Min Given PT less than current Min Position Taking of agent
											IF EXISTS (	SELECT 1
														FROM AgentPositionTaking AS apt WITH (NOLOCK)
															INNER JOIN @TablePositionTaking AS tpt 
																ON apt.SportType	= tpt.SportType
																AND apt.BetType		= tpt.BetType
																AND apt.IsLive		= tpt.IsLive
														WHERE apt.AgentId = @AgentId
															AND tpt.MinGivenPT < apt.MinGivenPositionTaking )
												BEGIN
													-- Get all member in downline of agent
													DELETE @TableCust

													INSERT INTO @TableCust(CustId)
													SELECT ci.CustId 
													FROM 
														CustInfo AS ci WITH (NOLOCK)
														INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
													WHERE ai.AgentHId.IsDescendantOf(@agentHId) = 1
														AND ai.AgentId <> @AgentId

													--DECLARE @TableCustAgent TABLE(CustId INT, AgentId INT,AgentLevel INT)

													WHILE EXISTS ( SELECT 1 FROM @TableCust )
														BEGIN
															-- Select current Cust Id
															SELECT TOP(1) @currentCustId = CustId
															FROM @TableCust

															DELETE @TableCustAgent

															INSERT INTO @TableCustAgent(
																CustId, 
																AgentId,
																AgentLevel)
															SELECT DISTINCT 
																cpt.CustId
																,ai.AgentId 
																,ai.AgentLevel
															FROM 
																CustPositionTaking AS cpt WITH (NOLOCK)	
																INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON cpt.AgentId = ai.AgentId
															WHERE 
																cpt.CustId = @currentCustId
																AND cpt.AgentId IN (	SELECT AgentId 
																						FROM AgentInfo WITH (NOLOCK)
																						WHERE ParentId = @AgentId )
															ORDER BY ai.AgentLevel

															SELECT TOP(1) @tempAgentId = AgentId 
															FROM @TableCustAgent

															DELETE @TableCustPositionTaking

															INSERT INTO @TableCustPositionTaking (
																CustId
																,SportType
																,BetType
																,IsLive
																,PositionTaking)
															SELECT 
																cpt.CustId
																,cpt.SportType
																,cpt.BetType
																,cpt.IsLive
																,CASE 
																	WHEN capt.MaxUpperPositionTaking > tpt.MinGivenPT - dcpt.SumOfPositionTaking
																		THEN capt.MaxUpperPositionTaking
																	ELSE tpt.MinGivenPT - dcpt.SumOfPositionTaking
																END
															FROM CustPositionTaking AS cpt WITH (NOLOCK)
																INNER JOIN @TablePositionTaking AS tpt
																	 ON cpt.SportType	= tpt.SportType
																	 AND cpt.BetType	= tpt.BetType
																	 AND cpt.IsLive		= tpt.IsLive
																INNER JOIN AgentPositionTaking AS capt WITH (NOLOCK)
																	ON cpt.SportType	= capt.SportType
																	 AND cpt.BetType	= capt.BetType
																	 AND cpt.IsLive		= capt.IsLive
																INNER JOIN (
																	SELECT 
																		CustId
																		,SportType
																		,BetType
																		,IsLive
																		,SUM(PositionTaking) AS SumOfPositionTaking
																	FROM 
																		CustPositionTaking AS cpt WITH (NOLOCK)
																		INNER JOIN AgentInfo AS ai WITH (NOLOCK)
																			ON cpt.AgentId	= ai.AgentId
																	WHERE cpt.CustId		= @currentCustId
																		AND ai.AgentLevel	> @agentLevel
																	GROUP BY 
																		CustId, 
																		SportType, 
																		BetType, 
																		IsLive	
																) AS dcpt 
																	ON 	cpt.SportType	= dcpt.SportType
																		AND cpt.BetType = dcpt.BetType
																		AND cpt.IsLive	= dcpt.IsLive
																		AND cpt.CustId  = dcpt.CustId
															WHERE cpt.AgentId			= @AgentId
																AND cpt.CustId			= @currentCustId
																AND capt.AgentId		= @tempAgentId
																AND cpt.PositionTaking	> capt.MaxUpperPositionTaking

															UPDATE cpt	
															SET cpt.PositionTaking = tcpt.PositionTaking	
															FROM CustPositionTaking AS cpt WITH (ROWLOCK, UPDLOCK)
																INNER JOIN @TableCustPositionTaking AS tcpt
																	 ON cpt.SportType	= tcpt.SportType
																	 AND cpt.BetType	= tcpt.BetType
																	 AND cpt.IsLive		= tcpt.IsLive
															WHERE cpt.AgentId	= @AgentId
																AND cpt.CustId	= @currentCustId

															IF EXISTS ( SELECT 1 FROM @TableCustPositionTaking )
																BEGIN
																	SET @currentAgentId = @AgentId

																	WHILE @currentAgentId IS NOT NULL
																		BEGIN
																			DELETE @UplineAgentInfo

																			INSERT INTO @UplineAgentInfo (
																				AgentId,
																				AgentLevel,
																				ParentId)
																			SELECT	
																				AgentId,
																				AgentLevel,
																				ParentId
																			FROM AgentInfo WITH (NOLOCK)
																			WHERE
																				@agentHId.IsDescendantOf(AgentHId) = 1
																				AND AgentId <> @AgentId
																				AND AgentId IN (	SELECT DISTINCT AgentId
																									FROM CustPositionTaking WITH (NOLOCK)
																									WHERE CustId = @currentCustId )

																			DELETE @TableStackPositionTaking

																			INSERT INTO @TableStackPositionTaking (
																				AgentId
																				,AgentLevel
																				,SportType
																				,BetType
																				,IsLive
																				,PT
																				,MinPT)
																			SELECT 
																				apt.AgentId
																				,uai.AgentLevel
																				,apt.SportType
																				,apt.BetType
																				,apt.IsLive
																				,cpt.PositionTaking
																				,apt.MinGivenPositionTaking
																			FROM 
																				AgentPositionTaking AS apt WITH (NOLOCK)
																				INNER JOIN @UplineAgentInfo AS uai ON apt.AgentId = uai.AgentId
																				INNER JOIN CustPositionTaking AS cpt WITH (NOLOCK)
																					ON apt.SportType	= cpt.SportType
																					AND apt.BetType		= cpt.BetType
																					AND apt.IsLive		= cpt.IsLive
																					AND apt.AgentId		= cpt.AgentId
																			WHERE 
																				cpt.CustId = @currentCustId
																				AND apt.MinGivenPositionTaking > 0

																			WHILE EXISTS( SELECT 1 FROM @UplineAgentInfo )
																				BEGIN
																					SELECT TOP 1
																						@tempAgentId = AgentId,
																						@tempLevel = AgentLevel
																					FROM @UplineAgentInfo

																					UPDATE tspt
																					SET	tspt.SumDownPT = temp.Sum
																					FROM 
																						@TableStackPositionTaking AS tspt
																						INNER JOIN (		
																							SELECT 
																								tcpt.SportType,
																								tcpt.BetType,
																								tcpt.IsLive,
																								SUM(tcpt.PositionTaking) AS Sum
																							FROM 
																								CustPositionTaking AS tcpt WITH (NOLOCK)
																								INNER JOIN AgentInfo AS tai WITH (NOLOCK) ON tcpt.AgentId = tai.AgentId
																							WHERE 
																								tcpt.CustId = @currentCustId
																								AND tai.AgentLevel >= @tempLevel
																							GROUP BY 
																								tcpt.SportType,
																								tcpt.BetType,
																								tcpt.IsLive
																						) AS temp
																							ON tspt.SportType	= temp.SportType
																							AND tspt.BetType	= temp.BetType
																							AND tspt.IsLive		= temp.IsLive
																					WHERE tspt.AgentLevel		= @tempLevel

																					DELETE @UplineAgentInfo 
																					WHERE AgentId = @tempAgentId
																				END

																				SET @currentAgentId = NULL

																				SELECT @currentAgentId = tspt.AgentId
																				FROM 
																					@TableStackPositionTaking AS tspt
																					INNER JOIN (
																						SELECT	
																							MAX(AgentLevel) AS AgentLevel,
																							SportType,
																							BetType,
																							IsLive 
																						FROM @TableStackPositionTaking
																						WHERE SumDownPT < MinPT
																						GROUP BY 
																							SportType,
																							BetType,
																							IsLive
																					) AS temp
																						ON 
																							tspt.SportType	= temp.SportType
																							AND tspt.BetType	= temp.BetType
																							AND tspt.IsLive		= temp.IsLive
																							AND tspt.AgentLevel	= temp.AgentLevel

																				UPDATE cpt
																				SET cpt.PositionTaking = tempUpdate.MinPT - tempUpdate.SumDownPT + tempUpdate.PT
																				FROM 
																					CustPositionTaking AS cpt WITH(ROWLOCK,UPDLOCK)
																					INNER JOIN (
																						SELECT 
																							tspt.AgentId
																							,tspt.AgentLevel
																							,tspt.SportType
																							,tspt.BetType
																							,tspt.IsLive
																							,tspt.PT
																							,tspt.MinPT
																							,tspt.SumDownPT
																						FROM 
																							@TableStackPositionTaking AS tspt
																							INNER JOIN (
																								SELECT	
																									MAX(AgentLevel) AS AgentLevel,
																									SportType,
																									BetType,
																									IsLive 
																								FROM @TableStackPositionTaking
																								WHERE SumDownPT < MinPT
																								GROUP BY 
																									SportType,
																									BetType,
																									IsLive
																							) AS temp
																						ON 
																							tspt.SportType	= temp.SportType
																							AND tspt.BetType	= temp.BetType
																							AND tspt.IsLive		= temp.IsLive
																							AND tspt.AgentLevel	= temp.AgentLevel
																					) AS tempUpdate
																						ON cpt.SportType	= tempUpdate.SportType
																						AND cpt.BetType		= tempUpdate.BetType
																						AND cpt.IsLive		= tempUpdate.IsLive
																						AND cpt.AgentId		= tempUpdate.AgentId
																				WHERE cpt.CustId = @currentCustId
																		END
																END
														
															-- Remove cust id
															DELETE @TableCust 
															WHERE CustId = @currentCustId
														END
												END
											-- End if New Min Given PT less than current Min Position Taking of agent 

										END
									-- End check for update Min Given PT of agent level k

									-- Update Min Given PT
									UPDATE apt
									SET apt.MinGivenPositionTaking	= tpt.MinGivenPT
									FROM AgentPositionTaking AS apt WITH (ROWLOCK, UPDLOCK)
										INNER JOIN @TablePositionTaking AS tpt
											ON tpt.SportType	= apt.SportType
											AND tpt.BetType		= apt.BetType
											AND tpt.IsLive		= apt.IsLive
									WHERE apt.AgentId = @AgentId

									-- End update Min Given PT
								END
							--(3)-- End edit Min Given PT
						
							--(2)-- Edit Max Given PT
							 IF EXISTS (	SELECT 1
											FROM AgentPositionTaking AS apt WITH (NOLOCK)
												INNER JOIN @TablePositionTaking AS tpt
													ON tpt.SportType	= apt.SportType
													AND tpt.BetType		= apt.BetType
													AND tpt.IsLive		= apt.IsLive
											WHERE apt.AgentId			= @AgentId
												AND apt.MaxGivenPositionTaking	<> tpt.MaxGivenPT )
								BEGIN								
									IF @isLastAgent = 1
										BEGIN
											SELECT TOP(1) 
												@sportType	= tpt.SportType
												,@betType	= tpt.BetType
												,@isLive	= tpt.IsLive
											FROM @TablePositionTaking AS tpt
												INNER JOIN AgentPositionTaking AS papt WITH (NOLOCK)
													ON tpt.SportType	= papt.SportType
													AND tpt.BetType		= papt.BetType
													AND tpt.IsLive		= papt.IsLive
											WHERE papt.AgentId	= @parentAgentId
												AND tpt.MaxGivenPT NOT BETWEEN tpt.MinGivenPT AND papt.MaxGivenPositionTaking

											 IF @sportType IS NOT NULL 
												BEGIN
													SELECT 
														@ErrCode	= 4006,
														@ErrMsg		= 
															CASE @Language
																WHEN 'en-US' THEN 'Invalid % Downline range' 
																ELSE [dbo].f_Msg_GetContentById (4006, @Language)
															END + ' (' 
																+ CASE WHEN @sportType = 99 AND @betType = 9
																		THEN [dbo].f_Msg_GetContentById (4009, @Language)
																		ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
																	END
																+ CASE WHEN @isLive = 1 THEN + ' ' + [dbo].f_Msg_GetContentById (4008, @Language) 
																		ELSE '' 
																	END
																+ ' - ' + dbo.f_Bet_GetNameByType(@betType, @Language) 
																+')'

													RETURN
												END
										END
									ELSE
										BEGIN
											SELECT TOP(1) 
												@sportType	= tpt.SportType
												,@betType	= tpt.BetType
												,@isLive	= tpt.IsLive
											FROM @TablePositionTaking AS tpt
												INNER JOIN (
													SELECT	
														downAgent.SportType
														,downAgent.BetType
														,downAgent.IsLive
														,MAX(downAgent.SumOfMaxUpperAndGiven) AS MaxOfMaxUpperAndGiven
													FROM (
															SELECT 
																ai.AgentId
																,apt.MaxUpperPositionTaking + apt.MaxGivenPositionTaking AS SumOfMaxUpperAndGiven
																,apt.SportType
																,apt.BetType
																,apt.IsLive
															FROM 
																AgentPositionTaking AS apt WITH (NOLOCK)
																INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON apt.AgentId = ai.AgentId
															WHERE ai.AgentHId.IsDescendantOf(@agentHId) = 1
																AND ai.AgentId <> @AgentId
														) AS downAgent	
													GROUP BY 
														downAgent.SportType
														,downAgent.BetType
														,downAgent.IsLive
												) AS maxDownAgent
													ON tpt.SportType	= maxDownAgent.SportType
													AND tpt.BetType		= maxDownAgent.BetType
													AND tpt.IsLive		= maxDownAgent.IsLive
												INNER JOIN AgentPositionTaking AS papt WITH (NOLOCK)
													ON tpt.SportType	= papt.SportType
													AND tpt.BetType		= papt.BetType
													AND tpt.IsLive		= papt.IsLive
											WHERE papt.AgentId = @parentAgentId
												AND tpt.MaxGivenPT NOT BETWEEN CASE WHEN maxDownAgent.MaxOfMaxUpperAndGiven > tpt.MinGivenPT
																					THEN maxDownAgent.MaxOfMaxUpperAndGiven
																					ELSE tpt.MinGivenPT
																				END	 AND papt.MaxGivenPositionTaking 
											IF @sportType IS NOT NULL 
												BEGIN
													SELECT 
														@ErrCode	= 4006,
														@ErrMsg		= 
															CASE @Language
																WHEN 'en-US' THEN 'Invalid % Downline range' 
																ELSE [dbo].f_Msg_GetContentById (4006, @Language)
															END + ' (' 
																+ CASE WHEN @sportType = 99 AND @betType = 9
																		THEN [dbo].f_Msg_GetContentById (4009, @Language)
																		ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
																	END
																+ CASE WHEN @isLive = 1 THEN + ' ' + [dbo].f_Msg_GetContentById (4008, @Language) 
																		ELSE '' 
																	END
																+ ' - ' + dbo.f_Bet_GetNameByType(@betType, @Language) 
																+')'

													RETURN
												END
										
										END		
									
									-- Update Max Given PT
									UPDATE apt
									SET apt.MaxGivenPositionTaking = tpt.MaxGivenPT
									FROM AgentPositionTaking AS apt WITH (ROWLOCK, UPDLOCK)
										INNER JOIN @TablePositionTaking AS tpt
											ON tpt.SportType	= apt.SportType
											AND tpt.BetType		= apt.BetType
											AND tpt.IsLive		= apt.IsLive
									WHERE apt.AgentId = @AgentId
									-- End update Max Given PT

									-- Update direct member if break rule Max Given PT
									-- Reset @TableCustPositionTaking
									DELETE @TableCustPositionTaking
								
									-- Get all direct member break rule PT > Max Given
									INSERT INTO @TableCustPositionTaking(
										CustId
										,SportType
										,BetType
										,IsLive
										,PositionTaking)
									SELECT 
										cpt.CustId
										,cpt.SportType
										,cpt.BetType
										,cpt.IsLive
										,cpt.PositionTaking 
									FROM CustPositionTaking AS cpt WITH (NOLOCK)
										INNER JOIN @TablePositionTaking AS tpt
											ON cpt.SportType	= tpt.SportType
											AND cpt.BetType		= tpt.BetType
											AND cpt.IsLive		= tpt.IsLive
										INNER JOIN CustInfo AS ci WITH (NOLOCK) ON cpt.CustId		= ci.CustId
									WHERE ci.AgentId	= @AgentId
										AND cpt.AgentId	= @AgentId
										AND cpt.PositionTaking > tpt.MaxGivenPT

									-- Update member
									UPDATE cpt
									SET cpt.PositionTaking	= tpt.MaxGivenPT
									FROM CustPositionTaking AS cpt WITH (ROWLOCK, UPDLOCK)
										INNER JOIN @TableCustPositionTaking AS tcpt
											ON cpt.SportType	= tcpt.SportType
											AND cpt.BetType		= tcpt.BetType
											AND cpt.IsLive		= tcpt.IsLive
											AND cpt.CustId		= tcpt.CustId
										INNER JOIN @TablePositionTaking AS tpt
											ON cpt.SportType	= tpt.SportType
											AND cpt.BetType		= tpt.BetType
											AND cpt.IsLive		= tpt.IsLive
									WHERE cpt.AgentId	= @AgentId
									-- End update member	

									--(Update Member When Down)-- Edit Position Taking of member for mem less than current mem pt										
									WHILE EXISTS ( SELECT 1 FROM @TableCustPositionTaking )
										BEGIN
											SET @currentAgentId = @AgentId

											SELECT TOP(1) @currentCustId = CustId
											FROM @TableCustPositionTaking

											WHILE @currentAgentId IS NOT NULL
												BEGIN
													DELETE @UplineAgentInfo

													INSERT INTO @UplineAgentInfo (
														AgentId,
														AgentLevel,
														ParentId)
													SELECT	
														AgentId,
														AgentLevel,
														ParentId
													FROM AgentInfo WITH (NOLOCK)
													WHERE
														@agentHId.IsDescendantOf(AgentHId) = 1
														AND AgentId <> @AgentId
														AND AgentId IN (	SELECT DISTINCT AgentId
																			FROM CustPositionTaking WITH (NOLOCK)
																			WHERE CustId = @currentCustId )
																				
													DELETE @TableStackPositionTaking

													INSERT INTO @TableStackPositionTaking (
														AgentId
														,AgentLevel
														,SportType
														,BetType
														,IsLive
														,PT
														,MinPT)
													SELECT 
														apt.AgentId
														,uai.AgentLevel
														,apt.SportType
														,apt.BetType
														,apt.IsLive
														,cpt.PositionTaking
														,apt.MinGivenPositionTaking
													FROM 
														AgentPositionTaking AS apt WITH (NOLOCK)
														INNER JOIN @UplineAgentInfo AS uai ON apt.AgentId = uai.AgentId
														INNER JOIN CustPositionTaking AS cpt WITH (NOLOCK)
															ON apt.SportType	= cpt.SportType
															AND apt.BetType		= cpt.BetType
															AND apt.IsLive		= cpt.IsLive
															AND apt.AgentId		= cpt.AgentId
													WHERE 
														cpt.CustId = @currentCustId
														AND apt.MinGivenPositionTaking > 0

													WHILE EXISTS( SELECT 1 FROM @UplineAgentInfo )
														BEGIN
															SELECT TOP 1
																@tempAgentId = AgentId,
																@tempLevel = AgentLevel
															FROM @UplineAgentInfo

															UPDATE tspt
															SET	tspt.SumDownPT = temp.Sum
															FROM 
																@TableStackPositionTaking AS tspt
																INNER JOIN (		
																	SELECT 
																		tcpt.SportType,
																		tcpt.BetType,
																		tcpt.IsLive,
																		SUM(tcpt.PositionTaking) AS Sum
																	FROM 
																		CustPositionTaking AS tcpt WITH (NOLOCK)
																		INNER JOIN AgentInfo AS tai WITH (NOLOCK) ON tcpt.AgentId = tai.AgentId
																	WHERE 
																		tcpt.CustId = @currentCustId
																		AND tai.AgentLevel >= @tempLevel
																	GROUP BY 
																		tcpt.SportType,
																		tcpt.BetType,
																		tcpt.IsLive
																) AS temp
																	ON tspt.SportType	= temp.SportType
																	AND tspt.BetType	= temp.BetType
																	AND tspt.IsLive		= temp.IsLive
															WHERE tspt.AgentLevel = @tempLevel

															DELETE @UplineAgentInfo 
															WHERE AgentId = @tempAgentId
														END

													SET @currentAgentId = NULL
													SELECT @currentAgentId = tspt.AgentId
													FROM 
														@TableStackPositionTaking AS tspt
														INNER JOIN (
															SELECT	
																MAX(AgentLevel) AS AgentLevel,
																SportType,
																BetType,
																IsLive 
															FROM @TableStackPositionTaking
															WHERE SumDownPT < MinPT
															GROUP BY 
																SportType,
																BetType,
																IsLive
														) AS temp
															ON 
																tspt.SportType	= temp.SportType
																AND tspt.BetType	= temp.BetType
																AND tspt.IsLive		= temp.IsLive
																AND tspt.AgentLevel	= temp.AgentLevel

													UPDATE cpt
													SET cpt.PositionTaking = tempUpdate.MinPT - tempUpdate.SumDownPT + tempUpdate.PT
													FROM 
														CustPositionTaking AS cpt WITH(ROWLOCK, UPDLOCK)
														INNER JOIN (
															SELECT 
																tspt.AgentId
																,tspt.AgentLevel
																,tspt.SportType
																,tspt.BetType
																,tspt.IsLive
																,tspt.PT
																,tspt.MinPT
																,tspt.SumDownPT
															FROM 
																@TableStackPositionTaking AS tspt
																INNER JOIN (
																	SELECT	
																		MAX(AgentLevel) AS AgentLevel,
																		SportType,
																		BetType,
																		IsLive 
																	FROM @TableStackPositionTaking
																	WHERE SumDownPT < MinPT
																	GROUP BY 
																		SportType,
																		BetType,
																		IsLive
																) AS temp
															ON 
																tspt.SportType	= temp.SportType
																AND tspt.BetType	= temp.BetType
																AND tspt.IsLive		= temp.IsLive
																AND tspt.AgentLevel	= temp.AgentLevel
														) AS tempUpdate
															ON cpt.SportType	= tempUpdate.SportType
															AND cpt.BetType		= tempUpdate.BetType
															AND cpt.IsLive		= tempUpdate.IsLive
															AND cpt.AgentId		= tempUpdate.AgentId
													WHERE cpt.CustId = @currentCustId
												END

											-- Remove cust
											DELETE @TableCustPositionTaking 
											WHERE CustId = @currentCustId
										END
									--(Update Member When Down)-- End edit Position Taking of member for mem less than current mem pt

									-- End update direct member if break rule Max Given PT

									-- Update Max Upper PT when greater than Max Given PT of Agent Parent - Max Given of current Agent
									DELETE @TableUpdatePositionTaking

									INSERT INTO @TableUpdatePositionTaking (
										SportType
										,BetType
										,IsLive
										,MaxUpperPT
										,MaxGivenPT)
									SELECT 
										apt.SportType
										,apt.BetType
										,apt.IsLive
										,apt.MaxUpperPositionTaking
										,apt.MaxGivenPositionTaking			-- Already updated with new value
									FROM AgentPositionTaking AS apt WITH (NOLOCK)
										INNER JOIN AgentPositionTaking AS papt WITH (NOLOCK)
											ON apt.SportType	= papt.SportType
											AND apt.BetType		= papt.BetType
											AND apt.IsLive		= papt.IsLive
										INNER JOIN @TablePositionTaking AS tpt
											ON apt.SportType	= tpt.SportType
											AND apt.BetType		= tpt.BetType
											AND apt.IsLive		= tpt.IsLive
									WHERE apt.AgentId		= @AgentId
										AND papt.AgentId	= @parentAgentId
										AND apt.MaxUpperPositionTaking > papt.MaxGivenPositionTaking - apt.MaxGivenPositionTaking

									IF EXISTS ( SELECT 1 FROM @TableUpdatePositionTaking )
										BEGIN
											-- Update new Max Upper PT
											UPDATE apt 
											SET apt.MaxUpperPositionTaking = papt.MaxGivenPositionTaking - tupt.MaxGivenPT	
											FROM AgentPositionTaking AS apt WITH (ROWLOCK, UPDLOCK)
												INNER JOIN AgentPositionTaking AS papt WITH (NOLOCK)
													ON apt.SportType	= papt.SportType
													AND apt.BetType		= papt.BetType
													AND apt.IsLive		= papt.IsLive
												INNER JOIN @TableUpdatePositionTaking AS tupt
													ON apt.SportType	= tupt.SportType
													AND apt.BetType		= tupt.BetType
													AND apt.IsLive		= tupt.IsLive
											WHERE apt.AgentId		= @AgentId
												AND papt.AgentId	= @parentAgentId
											-- End update new Max Upper PT

											--(Call Update Max Upper PT)--

												-- Reset @TableCust
												DELETE @TableCust
											
												-- Insert direct member of agent
												INSERT INTO @TableCust(CustId)
												SELECT CustId
												FROM CustInfo WITH (NOLOCK)
												WHERE AgentId = @AgentId

												-- Reset @TableCustPosistionTaking
												DELETE @TableCustPositionTaking

												-- Get all member break rule dirrect member of current agent
												INSERT INTO @TableCustPositionTaking(
													CustId
													,SportType
													,BetType
													,IsLive
													,PositionTaking)
												SELECT
													cpt.CustId
													,cpt.SportType
													,cpt.BetType
													,cpt.IsLive
													,cpt.PositionTaking 
												FROM CustPositionTaking AS cpt WITH (NOLOCK)	
													INNER JOIN @TableUpdatePositionTaking AS tupt
														ON tupt.SportType	= cpt.SportType
														AND tupt.BetType	= cpt.BetType
														AND tupt.IsLive		= cpt.IsLive
													INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
														ON cpt.SportType	= apt.SportType
														AND cpt.BetType		= apt.BetType
														AND cpt.IsLive		= apt.IsLive
													INNER JOIN @TableCust AS tc ON cpt.CustId = tc.CustId
												WHERE cpt.AgentId			= @parentAgentId	
													AND apt.AgentId			= @AgentId
													AND cpt.PositionTaking	> apt.MaxUpperPositionTaking

											-- Get member break rule of agent level k	
											IF @isLastAgent = 1
												BEGIN
												
												   -- Reset @TableCust
													DELETE @TableCust

													-- Get all indirect member
													INSERT INTO @TableCust(CustId)
													SELECT ci.CustId
													FROM 
														CustInfo AS ci WITH (NOLOCK)
														INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
													WHERE ai.AgentId <> @AgentId
														AND ai.AgentHId.IsDescendantOf(@agentHId) = 1

													-- Get all indirect member break rule of agent 
													INSERT INTO @TableCustPositionTaking(
														CustId
														,SportType
														,BetType
														,IsLive
														,PositionTaking)
													SELECT
														cpt.CustId
														,cpt.SportType
														,cpt.BetType
														,cpt.IsLive
														,cpt.PositionTaking 
													FROM CustPositionTaking AS cpt WITH (NOLOCK)	
														INNER JOIN @TableUpdatePositionTaking AS tupt
															ON tupt.SportType	= cpt.SportType
															AND tupt.BetType	= cpt.BetType
															AND tupt.IsLive		= cpt.IsLive
														INNER JOIN @TableCust AS tc ON cpt.CustId = tc.CustId
														INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
															ON apt.SportType	= cpt.SportType
															AND apt.BetType		= cpt.BetType
															AND apt.IsLive		= cpt.IsLive
													WHERE cpt.AgentId			= @parentAgentId
														AND apt.AgentId			= @AgentId
														AND cpt.PositionTaking	> apt.MaxUpperPositionTaking
														AND cpt.PositionTaking	<= tupt.MaxUpperPT
												END		
											
												-- Update member pt
												UPDATE cpt
												SET cpt.PositionTaking = 
													CASE 
														WHEN tupt.MaxUpperPT > papt.MinGivenPositionTaking - sumDown.SumDown
															THEN tupt.MaxUpperPT
														ELSE papt.MinGivenPositionTaking - sumDown.SumDown
													END
												FROM CustPositionTaking AS cpt WITH (ROWLOCK, UPDLOCK)
													INNER JOIN @TableUpdatePositionTaking AS tupt
														ON cpt.SportType	= tupt.SportType
														AND cpt.BetType		= tupt.BetType
														AND cpt.IsLive		= tupt.IsLive
													INNER JOIN (
														SELECT 
															cpt.CustId
															,cpt.SportType
															,cpt.BetType
															,cpt.IsLive
															,SUM(cpt.PositionTaking) AS SumDown
														FROM 
															CustPositionTaking AS cpt WITH (NOLOCK)
															INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON cpt.AgentId = ai.AgentId
															INNER JOIN @TableCustPositionTaking AS tcpt
																ON cpt.SportType	= tcpt.SportType
																AND cpt.BetType		= tcpt.BetType
																AND cpt.IsLive		= tcpt.IsLive
																AND cpt.CustId		= tcpt.CustId
														WHERE ai.AgentLevel > @agentParentLevel
														GROUP BY 
															cpt.CustId
															,cpt.SportType
															,cpt.BetType
															,cpt.IsLive
													) AS sumDown	
														ON cpt.SportType	= sumDown.SportType
														AND cpt.BetType		= sumDown.BetType
														AND cpt.IsLive		= sumDown.IsLive		
														AND cpt.CustId		= sumDown.CustId	
													INNER JOIN AgentPositionTaking AS papt WITH (NOLOCK)
														ON cpt.SportType	= papt.SportType
														AND cpt.BetType		= papt.BetType
														AND cpt.IsLive		= papt.IsLive
												WHERE papt.AgentId	= @parentAgentId	
													AND cpt.AgentId	= @parentAgentId
										
												--(Update Member When Down)-- Edit Position Taking of member for mem less than current mem pt

												WHILE EXISTS ( SELECT 1 FROM @TableCustPositionTaking )
													BEGIN
														DELETE @TableTempAgent

														INSERT INTO @TableTempAgent (AgentId)
														SELECT AgentId 
														FROM AgentInfo WITH (NOLOCK) 
														WHERE @agentParentHId.IsDescendantOf(AgentHId) = 1

														-- Edit Position Taking of member for mem less than current mem pt
														SELECT TOP(1) @currentCustId = CustId
														FROM @TableCustPositionTaking
												
														DELETE @TableStackPositionTaking

														INSERT INTO @TableStackPositionTaking(
															AgentId
															,AgentLevel
															,SportType
															,BetType
															,IsLive
															,PT
															,MinPT)
														SELECT 
															apt.AgentId
															,ai.AgentLevel
															,apt.SportType
															,apt.BetType
															,apt.IsLive
															,cpt.PositionTaking
															,apt.MinGivenPositionTaking 	
														FROM AgentPositionTaking AS apt WITH (NOLOCK)
															INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON apt.AgentId = ai.AgentId
															INNER JOIN CustPositionTaking AS cpt WITH (NOLOCK)
																ON apt.SportType	= cpt.SportType
																AND apt.BetType		= cpt.BetType
																AND apt.IsLive		= cpt.IsLive
																AND apt.AgentId		= cpt.AgentId
															INNER JOIN @TableCustPositionTaking AS tcpt
																ON cpt.SportType	= tcpt.SportType
																AND cpt.BetType		= tcpt.BetType
																AND cpt.IsLive		= tcpt.IsLive
																AND cpt.CustId		= tcpt.CustId
														WHERE 
															cpt.CustId = @currentCustId
															AND ai.AgentId IN ( SELECT AgentId FROM @TableTempAgent )

														WHILE EXISTS ( SELECT 1 FROM @TableTempAgent )
															BEGIN						
																SELECT TOP(1) @tempAgentId = AgentId
																FROM @TableTempAgent

																SELECT @tempLevel =	AgentLevel
																FROM AgentInfo WITH (NOLOCK)
																WHERE AgentId = @tempAgentId

																UPDATE tspt
																SET	tspt.SumDownPT = temp.Sum
																FROM 
																	@TableStackPositionTaking AS tspt
																	INNER JOIN (		
																		SELECT 
																			tcpt.SportType
																			,tcpt.BetType
																			,tcpt.IsLive
																			,SUM(tcpt.PositionTaking) AS Sum
																		FROM CustPositionTaking AS tcpt WITH (NOLOCK)
																			INNER JOIN AgentInfo AS tai WITH (NOLOCK)
																				ON tcpt.AgentId		= tai.AgentId
																		WHERE tcpt.CustId = @currentCustId		
																			AND tai.AgentLevel >= @tempLevel
																		GROUP BY 
																			tcpt.SportType
																			,tcpt.BetType
																			,tcpt.IsLive
																	) AS temp
																		ON tspt.SportType	= temp.SportType
																		AND tspt.BetType	= temp.BetType
																		AND tspt.IsLive		= temp.IsLive
																WHERE tspt.AgentLevel		= @tempLevel

																DELETE @TableTempAgent 
																WHERE AgentId = @tempAgentId 
															END
													
														UPDATE cpt
														SET cpt.PositionTaking = tempUpdate.MinPT - tempUpdate.SumDownPT + tempUpdate.PT
														FROM CustPositionTaking AS cpt WITH (ROWLOCK, UPDLOCK)
															INNER JOIN (
																SELECT 
																	tspt.AgentId
																	,tspt.AgentLevel
																	,tspt.SportType
																	,tspt.BetType
																	,tspt.IsLive
																	,tspt.PT
																	,tspt.MinPT
																	,tspt.SumDownPT
																FROM @TableStackPositionTaking AS tspt
																	INNER JOIN (
																		SELECT	
																			MAX(AgentLevel) AS AgentLevel
																			,SportType
																			,BetType
																			,IsLive 
																		FROM @TableStackPositionTaking
																		WHERE SumDownPT < MinPT
																		GROUP BY 
																			SportType
																			,BetType
																			,IsLive
																	) AS temp
																		ON tspt.SportType	= temp.SportType
																		AND tspt.BetType	= temp.BetType
																		AND tspt.IsLive		= temp.IsLive
																		AND tspt.AgentLevel	= temp.AgentLevel
															) AS tempUpdate
																ON cpt.SportType	= tempUpdate.SportType
																AND cpt.BetType		= tempUpdate.BetType
																AND cpt.IsLive		= tempUpdate.IsLive
																AND cpt.AgentId		= tempUpdate.AgentId
														WHERE cpt.CustId = @currentCustId

														-- Remove cust
														DELETE @TableCustPositionTaking 
														WHERE CustId = @currentCustId
													END
												--(Update Member When Down)-- End edit Position Taking of member for mem less than current mem pt											
											--(Call Update Max Upper PT)--
										END
									-- End update Max Upper PT when greater than Max Given PT of Agent Parent and current Agent

									-- End update Max Given PT		
								END
							--(2)-- End edit Max Given PT
												
						END
					-- End edit Agent with level k ( k > 1)

					-- write log before update
				
					SET @xml = (
						SELECT  
							SportType		AS '@s'
							,BetType		AS '@b'
							,IsLive			AS '@i'
							,MaxUpperPT		AS '@p'
							,MaxGivenPT		AS '@ma'
							,MinGivenPT		AS '@mi'
						FROM @TablePositionTaking
						--ORDER BY tpt.SportType
						--		,tpt.BetType
						--		,tpt.IsLive
						FOR XML PATH('z'), ROOT('r')
					)

					SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')
								
				END
				-- End update new position taking if had changed

			-- end update

				-- end write log
				SET @endRun		= GETDATE()  
				SET @duration	= DATEDIFF(MILLISECOND, @startRun, @endRun) 
								
				IF @@ERROR = 0
					BEGIN TRY
						EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
						@UserId		= @ActorAgentId,
						@AdminId	= @AdminId,
						@SPName		= 'Age_Agent_UpdatePositionTaking',
						@LogDate	= @startRun,
						@AgentId	= @AgentId,
						@Duration	= @Duration,
						@Data		= @logSPData,
						@OldData	= @logSPDataOld
					END	TRY
					BEGIN CATCH
						EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
						@UserId		= @ActorAgentId,
						@AdminId	= @AdminId,
						@SPName		= 'Age_Agent_UpdatePositionTaking',
						@LogDate	= @startRun,
						@AgentId	= @AgentId,
						@Duration	= @Duration,
						@Data		= @logSPData,
						@OldData	= @logSPDataOld
					END CATCH 
		END
END	
