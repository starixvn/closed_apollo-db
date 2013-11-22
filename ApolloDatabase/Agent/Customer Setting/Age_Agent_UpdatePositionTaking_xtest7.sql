USE [CustDB]
GO

/****** Object:  StoredProcedure [dbo].[Age_Agent_UpdatePositionTaking_xtest7]    Script Date: 11/12/2013 4:33:29 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Age_Agent_UpdatePositionTaking_xtest7    Script Date: 10/7/2013 4:56:44 PM ******/






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
CREATE PROCEDURE [dbo].[Age_Agent_UpdatePositionTaking_xtest7]
	@ActorAgentId			INT				= NULL,
	@AdminId				INT				= NULL,
	@AgentId				INT,
	@PositionTaking			VARCHAR(MAX)	= '',	
	@MemberPositionTaking	VARCHAR(MAX)	= '',	
	@Language				VARCHAR(5)		= 'en-US',	
	@ErrCode				INT				= 0			OUTPUT,
	@ErrMsg					NVARCHAR(1000)	= ''		OUTPUT
AS

/**
 * Created by	: Edward
 * Date			: 20130410
 * Task			: Update agent position taking
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	• 20131707@Edward	: Add parameter @AdminId for write log
 *	• 20132808@Edward	: Add parameter @MemberPositionTaking for apply preset to all member
 * Parameters:
 *	@PositionTaking :
		<ROOT>
		<PositionTaking SportType="1" BetType="1" IsLive="0" MaxUpper="122" MaxGiven="7761" MinGiven="0"></PositionTaking>
		</ROOT>		
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
	
	IF @PositionTaking <> ''
		BEGIN
			-- For read xml
			DECLARE @DocHandler INT

			-- Store new position taking of agent
			CREATE TABLE #TablePositionTaking (
				SportType	SMALLINT,
				BetType		SMALLINT,
				IsLive		BIT,
				MaxUpperPT	SMALLINT,
				MaxGivenPT	SMALLINT,
				MinGivenPT	SMALLINT,
				IsApply		BIT)

			-- write log before update
			SET @xml = (
				SELECT  
					SportType				AS '@s'
					,BetType				AS '@b'
					,IsLive					AS '@i'
					,MaxUpperPositionTaking	AS '@p'
					,MaxGivenPositionTaking	AS '@ma'
					,MinGivenPositionTaking	AS '@mi'
					,0						AS '@ia'
				FROM AgentPositionTaking WITH (NOLOCK)							
				WHERE AgentId = @AgentId	
				FOR XML PATH('z'), ROOT('r')
			)

			SET @logSPDataOld = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

			-- end write log before update

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
				,@changeMin			BIT				= 0

			---- Declare agentId
			DECLARE 
				@agentParentLevel		SMALLINT
				,@agentParentHId		HIERARCHYID
				,@parentOfParentAgentId	INT
				,@currentAgentId		INT
				,@childCurrentAgentId	INT
			---- End declare					

			-- Declare constant
			DECLARE	
				@MAINSHAREHOLDERLEVEL	SMALLINT	= 1
				,@SHAREHOLDERLEVEL		SMALLINT	= 2
				,@MAINAGENTLEVEL		SMALLINT	= 3
				,@MAXPT					SMALLINT	= 10000
				,@MAXSHAREHOLDERPT		SMALLINT	= 10000
				,@MINSHAREMUSTCOVER		SMALLINT	= 5000

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

			-- begin update									
			-- Check current agent is last agent ?
			IF EXISTS ( SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE ParentId = @AgentId )
				SET @isLastAgent = 0
			ELSE
				SET @isLastAgent = 1					
		
			DECLARE @TableUpdatePositionTaking TABLE (
				SportType	SMALLINT,
				BetType		SMALLINT,
				IsLive		BIT,
				MaxUpperPT	SMALLINT,
				MaxGivenPT	SMALLINT,
				MinGivenPT	SMALLINT)		
					
			DECLARE @TableChildAgent TABLE (AgentId INT)  																  						

			-- For read xml					
			EXEC sp_xml_preparedocument @DocHandler OUTPUT, @PositionTaking

			INSERT INTO #TablePositionTaking(
				SportType,
				BetType,
				IsLive,
				MaxUpperPT,
				MaxGivenPT,
				MinGivenPT,
				IsApply)
			SELECT
				Data.SportType,
				Data.BetType,
				Data.IsLive,
				Data.MaxUpper,
				Data.MaxGiven,
				Data.MinGiven,
				1
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

			/*	Check validate : 
				+ MaxUpper > 0 
				+ MaxGiven > 0 
				+ MinGiven > 0
			*/
			SELECT TOP(1) 
				@sportType	= SportType
				,@betType	= BetType
				,@isLive	= IsLive
			FROM #TablePositionTaking
			WHERE MinGivenPT	< 0
				OR MaxGivenPT	< 0
				OR MaxUpperPT	< 0 

			IF @sportType IS NOT NULL 
			BEGIN
				SELECT 
					@ErrCode = 4002,
					@ErrMsg	= 
						CASE @Language
							WHEN 'en-US' THEN '% Share must be equal or greater than zero' 
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

			/*	Check validate :
				+ MinGiven <= MaxGiven  
			*/
			SELECT TOP(1) 
				@sportType	= SportType
				,@betType	= BetType
				,@isLive	= IsLive
			FROM #TablePositionTaking
			WHERE MinGivenPT > MaxGivenPT

			IF @sportType IS NOT NULL 
			BEGIN
				SELECT 
					@ErrCode = 4003,
					@ErrMsg	= 
						CASE @Language
							WHEN 'en-US' THEN '% Min Downline must be equal to or less than % Max Downline' 
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

			/*	Check validate :
				+ SUM[MaxUpper(k),MaxGiven(k)] <= MaxGiven(k-1) 
			*/
			SELECT TOP(1) 
				@sportType		= tpt.SportType
				,@tempAgentId	= apt.AgentId
				,@betType		= tpt.BetType
				,@isLive		= tpt.IsLive
			FROM #TablePositionTaking AS tpt
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
							WHEN 'en-US' THEN 'Sum % Preset and % Max Downline must be equal or less than % Max Downline of Parent Agent' 
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
		
			/*	Check validate :
				+ MAX[MinGiven(k-1) - MaxGiven(k),0] <= MaxUpper(k) <= MaxGiven(k-1) - MaxGiven(k)  
			*/
			SELECT TOP(1) 
				@sportType	= tpt.SportType
				,@betType	= tpt.BetType
				,@isLive	= tpt.IsLive
			FROM 
				#TablePositionTaking AS tpt
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

			/*	Check validate :
				+ Main shareholder	: MaxGiven >= 50%
				+ Shareholder		: MaxGiven >= 50% and MinGiven >= 50%				
			*/
			SELECT TOP(1) 
				@sportType	= tpt.SportType
				,@betType	= tpt.BetType
				,@isLive	= tpt.IsLive
			FROM #TablePositionTaking AS tpt					
			WHERE (@agentLevel < @SHAREHOLDERLEVEL AND tpt.MaxGivenPT	< @MINSHAREMUSTCOVER)
					OR( @agentLevel			= @SHAREHOLDERLEVEL
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
							INNER JOIN #TablePositionTaking AS tpt
								ON tpt.SportType	= apt.SportType
								AND tpt.BetType		= apt.BetType
								AND tpt.IsLive		= apt.IsLive
						WHERE apt.AgentId = @AgentId
							AND (apt.MaxUpperPositionTaking		<> tpt.MaxUpperPT
									OR apt.MaxGivenPositionTaking	<> tpt.MaxGivenPT
									OR apt.MinGivenPositionTaking	<> tpt.MinGivenPT ) )
			BEGIN				

				IF @isLastAgent = 1
				BEGIN

					/*	Check validate for Agent(n):
						+ MinGiven(k-1) <= MaxGiven(k) <= MaxGiven(k-1)
					*/
					SELECT TOP(1) 
						@sportType	= tpt.SportType
						,@betType	= tpt.BetType
						,@isLive	= tpt.IsLive
					FROM #TablePositionTaking AS tpt
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
									WHEN 'en-US' THEN 'Invalid % Max Downline range' 
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

					/*	Check validate for Agent(k):
						+ MAX(SUM[MaxUpper(k+1),MaxGiven(k+1)],MinGiven(k)) <= MaxGiven(k) <= MaxGiven(k-1)
					*/
					SELECT TOP(1) 
						@sportType	= tpt.SportType
						,@betType	= tpt.BetType
						,@isLive	= tpt.IsLive
					FROM #TablePositionTaking AS tpt
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
									WHEN 'en-US' THEN 'Invalid % Max Downline range' 
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
									INNER JOIN #TablePositionTaking AS tpt
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
						FROM #TablePositionTaking
						WHERE MaxGivenPT NOT BETWEEN MinGivenPT AND @MAXSHAREHOLDERPT

						IF @sportType IS NOT NULL 
						BEGIN
							SELECT 
								@ErrCode = 4004,
								@ErrMsg	= 
									CASE @Language
										WHEN 'en-US' THEN '% Max Downline must be equal to or less than 100%' 
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
						FROM #TablePositionTaking AS tpt
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
										WHEN 'en-US' THEN 'Invalid % Max Downline range' 
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
							INNER JOIN #TablePositionTaking AS tpt
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
								INNER JOIN #TablePositionTaking AS tpt
									ON tpt.SportType	= apt.SportType
									AND tpt.BetType		= apt.BetType
									AND tpt.IsLive		= apt.IsLive
							WHERE apt.AgentId = @AgentId
								AND apt.MinGivenPositionTaking	<> tpt.MinGivenPT )
					BEGIN
																	
						UPDATE apt
						SET apt.MinGivenPositionTaking	= tpt.MinGivenPT
						FROM AgentPositionTaking AS apt WITH (ROWLOCK, UPDLOCK)
							INNER JOIN #TablePositionTaking AS tpt
								ON apt.SportType	= tpt.SportType
								AND apt.BetType		= tpt.BetType
								AND apt.IsLive		= tpt.IsLive
						WHERE apt.AgentId = @AgentId
						-- End update

						SET @changeMin = 1
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
									INNER JOIN #TablePositionTaking AS tpt
										ON tpt.SportType	= apt.SportType
										AND tpt.BetType		= apt.BetType
										AND tpt.IsLive		= apt.IsLive
								WHERE apt.AgentId = @AgentId
									AND apt.MaxUpperPositionTaking	<> tpt.MaxUpperPT )
					BEGIN											
											
						-- Update Max Upper PT
						UPDATE apt
						SET apt.MaxUpperPositionTaking	= tpt.MaxUpperPT
						FROM AgentPositionTaking AS apt WITH (ROWLOCK, UPDLOCK)
							INNER JOIN #TablePositionTaking AS tpt
								ON apt.SportType	= tpt.SportType
								AND apt.BetType		= tpt.BetType
								AND apt.IsLive		= tpt.IsLive
						WHERE apt.AgentId = @AgentId 
					END
					--(1)-- End edit Max Upper PT	

					--(3)-- Edit Min Given PT
					IF EXISTS (	SELECT 1
								FROM AgentPositionTaking AS apt WITH (NOLOCK)
									INNER JOIN #TablePositionTaking AS tpt
										ON tpt.SportType	= apt.SportType
										AND tpt.BetType		= apt.BetType
										AND tpt.IsLive		= apt.IsLive
								WHERE apt.AgentId = @AgentId
									AND apt.MinGivenPositionTaking <> tpt.MinGivenPT )
					BEGIN									

						-- Update Min Given PT
						UPDATE apt
						SET apt.MinGivenPositionTaking	= tpt.MinGivenPT
						FROM AgentPositionTaking AS apt WITH (ROWLOCK, UPDLOCK)
							INNER JOIN #TablePositionTaking AS tpt
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
									INNER JOIN #TablePositionTaking AS tpt
										ON tpt.SportType	= apt.SportType
										AND tpt.BetType		= apt.BetType
										AND tpt.IsLive		= apt.IsLive
								WHERE apt.AgentId			= @AgentId
									AND apt.MaxGivenPositionTaking	<> tpt.MaxGivenPT )
					BEGIN																						
											
						-- Update Max Given PT
						UPDATE apt
						SET apt.MaxGivenPositionTaking = tpt.MaxGivenPT
						FROM AgentPositionTaking AS apt WITH (ROWLOCK, UPDLOCK)
							INNER JOIN #TablePositionTaking AS tpt
								ON tpt.SportType	= apt.SportType
								AND tpt.BetType		= apt.BetType
								AND tpt.IsLive		= apt.IsLive
						WHERE apt.AgentId = @AgentId
						-- End update Max Given PT
											
						-- End update Max Given PT		
					END
					--(2)-- End edit Max Given PT																																
				END
				-- End edit Agent with level k ( k > 1)						
					
				-- Has change position taking on member
				IF @agentLevel <> @MAINSHAREHOLDERLEVEL	OR @changeMin = 1
				BEGIN
					-- Get data for all line
					CREATE TABLE #TableAllLinePositionTaking (
						AgentId						INT
						,ParentAgentId				INT
						,ParentAgentLevel			SMALLINT
						,SportType					SMALLINT
						,BetType					SMALLINT
						,IsLive						BIT						
						,NewMaxUpperPositionTaking	SMALLINT
						,NewMaxGivenPositionTaking	SMALLINT
						,NewMinGivenPositionTaking	SMALLINT
						,PositionTaking				SMALLINT
						,SumPositionTaking			SMALLINT
						,NewPositionTaking			SMALLINT						
						,NewSumPositionTaking		SMALLINT	
						,MemPositionTaking			SMALLINT
						,RootID						INT
					)					
					
					/*	Get position taking of downline, from Agent(n + 1) to upline */					
					INSERT INTO #TableAllLinePositionTaking(
						AgentId
						,ParentAgentId
						,ParentAgentLevel
						,SportType
						,BetType
						,IsLive						
						,NewMaxUpperPositionTaking
						,NewMaxGivenPositionTaking
						,NewMinGivenPositionTaking
						,PositionTaking
					)
					SELECT ai.AgentId
							,pai.AgentId
							,pai.AgentLevel
							,apt.SportType
							,apt.BetType
							,apt.IsLive							
							,apt.MaxUpperPositionTaking
							,apt.MaxGivenPositionTaking
							,apt.MinGivenPositionTaking
							,NULL--acpt.PositionTaking	 							
					FROM AgentInfo AS ai WITH (NOLOCK)
						INNER JOIN AgentInfo AS pai WITH (NOLOCK)
							ON ai.AgentHId.IsDescendantOf(pai.AgentHId) = 1	 	
							AND pai.AgentLevel	> 0
						INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
							ON pai.AgentId	= apt.AgentId	
						INNER JOIN #TablePositionTaking AS tpt
							ON apt.SportType	= tpt.SportType
							AND apt.BetType		= tpt.BetType
							AND apt.IsLive		= tpt.IsLive
						--INNER JOIN AgentCustPositionTaking AS acpt WITH (NOLOCK)
						--	ON ai.AgentId		= acpt.AgentCustId
						--	AND pai.AgentId		= acpt.AgentId
						--	AND apt.SportType	= acpt.SportType
						--	AND apt.BetType		= acpt.BetType
						--	AND apt.IsLive		= acpt.IsLive					
					WHERE ai.AgentHId.IsDescendantOf(@agentHId) = 1	
							AND pai.AgentLevel <= @AgentLevel + 1
					OPTION (RECOMPILE)
					-- End get date for all line

					IF @@ROWCOUNT>= 10000
					BEGIN
						--CREATE CLUSTERED INDEX IX_C_#TableAllLinePositionTaking 
						CREATE NONCLUSTERED INDEX IX_C_#TableAllLinePositionTaking 
							ON #TableAllLinePositionTaking (AgentId, SportType, BetType, IsLive, ParentAgentLevel)  	
							include (ParentAgentId)
							
					END

					-- get current PT
					UPDATE T
					SET t.PositionTaking=acpt.PositionTaking
					FROM #TableAllLinePositionTaking as T 
						JOIN AgentCustPositionTaking AS acpt WITH (NOLOCK)
							ON T.AgentId		= acpt.AgentCustId
							AND t.ParentAgentId		= acpt.AgentId
							AND t.SportType	= acpt.SportType
							AND t.BetType		= acpt.BetType
							AND t.IsLive		= acpt.IsLive	


					-- Edit position taking on member
					
					/* Set RootId is max agent level for recursion */	
					UPDATE t
					SET	t.RootID	= t.AgentId
					FROM #TableAllLinePositionTaking AS t WITH (NOLOCK)					
						INNER JOIN(
							SELECT AgentId
									,SportType
									,BetType
									,IsLive			
									,MAX(ParentAgentLevel) AS MaxParentLevel 
							FROM #TableAllLinePositionTaking		
							GROUP BY AgentId
									,SportType
									,BetType
									,IsLive	
					) AS temp
						ON temp.AgentId			= t.AgentId
						AND temp.MaxParentLevel	= t.ParentAgentLevel
						AND temp.SportType		= t.SportType
						AND temp.BetType		= t.BetType
						AND temp.IsLive			= t.IsLive
					/* End Set RootId is max agent level for recursion */
					
					CREATE NONCLUSTERED INDEX IX_Temp		
							ON #TableAllLinePositionTaking (RootID, AgentId, ParentAgentId) 
							include (SportType,BetType,IsLive )

					/*  Update sum downline for indirect member
					*/			
					UPDATE t
					SET t.SumPositionTaking = temp.SumDown					
					FROM #TableAllLinePositionTaking AS t
					INNER JOIN (						
						SELECT  t.AgentId
								,t.ParentAgentId
								,t.SportType
								,t.BetType
								,t.IsLive 
								,SUM(apt.PositionTaking) AS SumDown									
						FROM #TableAllLinePositionTaking AS t WITH (NOLOCK)											
						INNER JOIN AgentCustPositionTaking AS apt WITH (NOLOCK)
							ON t.AgentId	= apt.AgentCustId
							AND t.SportType	= apt.SportType
							AND t.BetType	= apt.BetType
							AND t.IsLive	= apt.IsLive											
						INNER JOIN AgentInfo AS ai WITH (NOLOCK)
							ON apt.AgentId	= ai.AgentId
							AND t.ParentAgentLevel	<= ai.AgentLevel
						WHERE t.RootID IS NOT NULL
							AND t.AgentId	<> t.ParentAgentId				
						GROUP BY t.AgentId
								,t.ParentAgentId
								,t.SportType
								,t.BetType
								,t.IsLive
					) AS temp
						ON t.SportType	= temp.SportType
						AND t.BetType	= temp.BetType
						AND t.IsLive	= temp.IsLive
						AND t.AgentId	= temp.AgentId
						AND t.ParentAgentId	= temp.ParentAgentId					

					/*	Update sum downline for direct member
					*/
					UPDATE pt
					SET pt.SumPositionTaking		= pt.PositionTaking	
					FROM #TableAllLinePositionTaking AS pt					
					WHERE pt.RootID IS NOT NULL
						AND pt.AgentId	= pt.ParentAgentId

					UPDATE pt
					SET pt.SumPositionTaking		= temp.SumDownLine	
					FROM #TableAllLinePositionTaking AS pt
						INNER JOIN (
							SELECT 	
									pt.AgentId
									,pt.ParentAgentId
									,pt.SportType
									,pt.BetType
									,pt.IsLive									
									,SUM(ISNULL(pt1.SumPositionTaking,pt1.PositionTaking))	AS SumDownLine				
							FROM #TableAllLinePositionTaking AS pt 
								LEFT JOIN #TableAllLinePositionTaking AS pt1 
									ON pt.AgentId			= pt1.AgentId
									AND pt.ParentAgentLevel	<= pt1.ParentAgentLevel
									AND pt.SportType		= pt1.SportType
									AND pt.BetType			= pt1.BetType
									AND pt.IsLive			= pt1.IsLive
							GROUP BY pt.AgentId	 
									,pt.ParentAgentId
									,pt.SportType
									,pt.BetType
									,pt.IsLive
						) AS temp
							ON pt.AgentId			= temp.AgentId
							AND pt.ParentAgentId	= temp.ParentAgentId
							AND pt.SportType		= temp.SportType
							AND pt.BetType			= temp.BetType
							AND pt.IsLive			= temp.IsLive				
	

					/* Update new position taking for direct member and set new sum = new pt
					*/
					UPDATE #TableAllLinePositionTaking
					SET NewPositionTaking = CASE	
												WHEN PositionTaking < NewMinGivenPositionTaking THEN NewMinGivenPositionTaking
												WHEN PositionTaking > NewMaxGivenPositionTaking THEN NewMaxGivenPositionTaking
												ELSE PositionTaking
											END
						,NewSumPositionTaking= CASE	
												WHEN PositionTaking < NewMinGivenPositionTaking THEN NewMinGivenPositionTaking
												WHEN PositionTaking > NewMaxGivenPositionTaking THEN NewMaxGivenPositionTaking
												ELSE PositionTaking
											END		
					WHERE AgentId = ParentAgentId	
						AND RootID IS NOT NULL


					UPDATE pt
					SET pt.NewPositionTaking		= CASE	WHEN pt.NewMinGivenPositionTaking - pt.SumPositionTaking > 0 
															THEN pt.NewMinGivenPositionTaking - pt.SumPositionTaking 
															ELSE pt.PositionTaking 
													END	
						,pt.NewSumPositionTaking	= CASE	WHEN pt.NewMinGivenPositionTaking - pt.SumPositionTaking > 0 
															THEN pt.NewMinGivenPositionTaking
															ELSE pt.SumPositionTaking 
													END 
					FROM #TableAllLinePositionTaking AS pt					
					WHERE pt.RootID IS NOT NULL
						AND pt.AgentId	<> pt.ParentAgentId											

					UPDATE pt
					SET pt.NewPositionTaking	= ISNULL(pt1.NewMaxUpperPositionTaking,pt.NewPositionTaking)						
					FROM #TableAllLinePositionTaking AS pt 
						LEFT JOIN #TableAllLinePositionTaking AS pt1 
							ON pt.AgentId			= pt1.AgentId
							AND pt.ParentAgentLevel	= pt1.ParentAgentLevel - 1
							AND pt.SportType		= pt1.SportType
							AND pt.BetType			= pt1.BetType
							AND pt.IsLive			= pt1.IsLive
					
					;WITH Temp AS(
						SELECT t.AgentId
								,t.ParentAgentId
								,t.ParentAgentLevel
								,t.SportType
								,t.BetType
								,t.IsLive
								,t.NewMaxUpperPositionTaking
								,t.NewMaxGivenPositionTaking
								,t.NewMinGivenPositionTaking
								,t.PositionTaking
								,t.SumPositionTaking
								,t.NewPositionTaking
								,t.NewSumPositionTaking
								,ISNULL(t.MemPositionTaking,t.NewSumPositionTaking)  AS MemPositionTaking
								,t.RootID
						FROM #TableAllLinePositionTaking AS t
						WHERE t.RootID = t.AgentId
							AND t.RootID IS NOT NULL

						UNION ALL

						SELECT t.AgentId
								,t.ParentAgentId
								,t.ParentAgentLevel
								,t.SportType
								,t.BetType
								,t.IsLive
								,t.NewMaxUpperPositionTaking
								,t.NewMaxGivenPositionTaking
								,t.NewMinGivenPositionTaking
								,t.PositionTaking
								,t.SumPositionTaking
								,t.NewPositionTaking
								,CASE WHEN t.NewMinGivenPositionTaking -t1.NewSumPositionTaking > t1.NewMaxUpperPositionTaking
													THEN t.NewMinGivenPositionTaking -t1.NewSumPositionTaking 
													ELSE t1.NewMaxUpperPositionTaking 
												END + t1.NewSumPositionTaking AS NewSumPositionTaking 
								,CASE WHEN t.NewMinGivenPositionTaking -t1.NewSumPositionTaking > t1.NewMaxUpperPositionTaking
													THEN t.NewMinGivenPositionTaking -t1.NewSumPositionTaking 
													ELSE t1.NewMaxUpperPositionTaking 
												END	AS MemPositionTaking
								,t.RootID
						FROM #TableAllLinePositionTaking AS t
							INNER JOIN Temp AS t1
								ON t.AgentId			= t1.AgentId
								AND t.ParentAgentLevel	= t1.ParentAgentLevel - 1
								AND t.SportType			= t1.SportType
								AND t.BetType			= t1.BetType
								AND t.IsLive			= t1.IsLive
					)

					/* Update position taking on member */ 
					UPDATE acpt 
					SET	acpt.PositionTaking = tapt.MemPositionTaking
					FROM AgentCustPositionTaking AS acpt WITH (ROWLOCK, UPDLOCK)						
						INNER JOIN Temp AS tapt
							ON acpt.AgentCustId	= tapt.AgentId
							AND acpt.AgentId	= tapt.ParentAgentId
							AND acpt.SportType	= tapt.SportType
							AND acpt.BetType	= tapt.BetType
							AND acpt.IsLive		= tapt.IsLive																		
					WHERE acpt.PositionTaking	<> tapt.MemPositionTaking
						AND tapt.ParentAgentLevel <= @AgentLevel
					DROP TABLE #TableAllLinePositionTaking
					-- End edit position taking on member 
				END																					
				-- End update new position taking if had changed 						
			END		

			-- Write log after update
			SET @xml = (
				SELECT SportType	AS '@s'
					,BetType		AS '@b'
					,IsLive			AS '@i'
					,MaxUpperPT		AS '@p'
					,MaxGivenPT		AS '@ma'
					,MinGivenPT		AS '@mi'
					,IsApply		AS '@ia'
				FROM #TablePositionTaking								
				FOR XML PATH('z'), ROOT('r')
			)

			DROP TABLE #TablePositionTaking

			SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

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
GO

GRANT EXECUTE ON [dbo].[Age_Agent_UpdatePositionTaking_xtest7] TO [aplweb] AS [dbo]
GO


