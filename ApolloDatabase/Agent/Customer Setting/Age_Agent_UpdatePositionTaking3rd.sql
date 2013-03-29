USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_UpdatePositionTaking3rd]    Script Date: 3/29/2013 10:39:24 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_UpdatePositionTaking3rd]
	@ActorAgentId		INT				= NULL,
	@AgentId			INT,
	@PositionTaking		VARCHAR(MAX)	= '',
	@Language			VARCHAR(2)		= 'E',
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsg				NVARCHAR(1000)	= ''		OUTPUT,
	@LogData			NVARCHAR(MAX)	= ''		OUTPUT,
	@LogOldData			NVARCHAR(MAX)	= ''		OUTPUT 			
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Update agent position taking 3rd
 * DB			: APL.CustDB
* Revisions	:
 *	• 20132702@Edward	: Implement
 * Parameters:
 *	• @PositionTaking : 
		<ROOT>
			<PositionTaking SportType="4" BetType="4" IsLive="1" Preset="10" Max="1" Min="1"></PositionTaking>
		</ROOT>
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	DECLARE @xml	XML	
	
	IF @PositionTaking <> ''
	BEGIN	
		
		-- Declare variable
		DECLARE @agentHId				HIERARCHYID
				,@parentAgentId			INT
				,@agentLevel			INT
				,@MAINSHAREHOLDERLEVEL	INT
				,@SHAREHOLDERLEVEL		INT
				,@MAINAGENTLEVEL		INT
				,@MAXPT					SMALLINT
				,@MAXSHAREHOLDERPT		SMALLINT
				,@sportType				SMALLINT

		-- Set value
		SELECT @MAXPT					= 10000
				,@MAXSHAREHOLDERPT		= 9000
				,@MAINAGENTLEVEL		= 3
				,@SHAREHOLDERLEVEL		= 2
				,@MAINSHAREHOLDERLEVEL	= 1	 		

		-- Get agent hierarchy ID
		SELECT 
			@agentHId		= AgentHId
			,@parentAgentId	= ParentId
			,@agentLevel	= AgentLevel
		FROM 
			AgentInfo WITH (NOLOCK)
		WHERE 
			AgentId = @AgentId

		-- Store new position taking of agent
		DECLARE @TablePositiongTaking TABLE(
			SportType				SMALLINT,
			BetType					SMALLINT,
			IsLive					BIT,
			PresetPositionTaking	SMALLINT,
			MaxPositionTaking		SMALLINT)
		
		DECLARE @TableStackPositiongTaking TABLE(
			AgentId					INT,			
			SportType				SMALLINT,
			BetType					SMALLINT,
			IsLive					BIT,
			PresetPositionTaking	SMALLINT,
			MaxPositionTaking		SMALLINT)		
	
		DECLARE @TableAgent	TABLE(AgentId INT)

		-- For read xml
		DECLARE @DocHandler int

		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @PositionTaking

		INSERT INTO @TablePositiongTaking(
			SportType,
			BetType,
			IsLive,
			PresetPositionTaking,			
			MaxPositionTaking)					
		SELECT 			
			Data.SportType,
			Data.BetType,
			Data.IsLive,
			Data.Preset,			
			Data.Max
		FROM OPENXML (@DocHandler, '/ROOT/PositionTaking',1) 
		WITH (			
			SportType		SMALLINT,
			BetType			SMALLINT,
			IsLive			BIT,
			Preset			SMALLINT,			
			Max				SMALLINT
		) AS Data

		EXEC sp_xml_removedocument @DocHandler
		-- end read xml	

		IF @agentLevel = @MAINSHAREHOLDERLEVEL
			BEGIN

				-- Check validate when update main share holder
				SELECT TOP(1) @sportType = tpt.SportType
				FROM @TablePositiongTaking AS tpt					
				WHERE tpt.MaxPositionTaking NOT BETWEEN 0 AND @MAXSHAREHOLDERPT

				IF @sportType IS NOT NULL 
					BEGIN
						SELECT @ErrCode = 1

						----Message for each sport type	WITH CASE @sportType
						SELECT @ErrMsg	= 'Position taking must be equal to or less than 90%.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

						RETURN			
					END
			END
		ELSE IF @agentLevel = @MAINAGENTLEVEL
				BEGIN

					-- Check validate when update main agent
					SELECT TOP(1) @sportType = tpt.SportType
					FROM @TablePositiongTaking AS tpt
						INNER JOIN AgentPositionTaking3rd AS apt WITH (NOLOCK)
							ON apt.SportType	= tpt.SportType
							AND apt.BetType		= tpt.BetType
							AND apt.IsLive		= tpt.IsLive
					WHERE apt.AgentId = @parentAgentId
						AND ( tpt.PresetPositionTaking < 0 
								OR tpt.MaxPositionTaking < 0
								OR tpt.PresetPositionTaking + tpt.MaxPositionTaking > apt.MaxPositionTaking)
					
					IF @sportType IS NOT NULL 
					BEGIN
						SELECT @ErrCode = 1

						----Message for each sport type	WITH CASE @sportType
						SELECT @ErrMsg	= 'Sum position taking of preset and max must be equal to or less than Parent Agent position taking.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

						RETURN			
					END	
				END
			ELSE
				BEGIN

					-- Check validate when update agent(k)
					SELECT TOP(1) @sportType = tpt.SportType
					FROM @TablePositiongTaking AS tpt
						INNER JOIN AgentPositionTaking3rd AS apt WITH (NOLOCK)
							ON apt.SportType	= tpt.SportType
							AND apt.BetType		= tpt.BetType
							AND apt.IsLive		= tpt.IsLive
					WHERE apt.AgentId = @parentAgentId
						AND ( tpt.MaxPositionTaking < 0
								OR tpt.MaxPositionTaking > apt.MaxPositionTaking)
					
					IF @sportType IS NOT NULL 
					BEGIN
						SELECT @ErrCode = 1

						----Message for each sport type	WITH CASE @sportType
						SELECT @ErrMsg	= 'Max position taking must be equal to or less than Parent Agent position taking.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

						RETURN			
					END	
				END

			-- Update preset position taking for agent
		IF @agentLevel <> @MAINAGENTLEVEL
			BEGIN
				UPDATE 
					tpt
				SET 
					tpt.PresetPositionTaking = CASE WHEN @agentLevel = 1
													THEN @MAXPT - tpt.MaxPositionTaking
													ELSE apt.MaxPositionTaking - tpt.MaxPositionTaking
												END
				FROM @TablePositiongTaking AS tpt
					INNER JOIN AgentPositionTaking3rd AS apt WITH (NOLOCK)
						ON apt.SportType	= tpt.SportType
						AND apt.BetType		= tpt.BetType
						AND apt.IsLive		= tpt.IsLive
				WHERE apt.AgentId = @parentAgentId
			END

		IF EXISTS (			
			SELECT TOP(1) *
			FROM 
				AgentPositionTaking3rd AS apt WITH (NOLOCK)
			INNER JOIN @TablePositiongTaking AS tapt
				ON apt.SportType	= tapt.SportType
				AND apt.BetType		= tapt.BetType
				AND apt.IsLive		= tapt.IsLive
			WHERE apt.AgentId = @AgentId
				AND (
					(apt.PresetPositionTaking	<> tapt.PresetPositionTaking AND @agentLevel = @MAINAGENTLEVEL)
					OR apt.MaxPositionTaking	<> tapt.MaxPositionTaking
				)
		)
			BEGIN
				
				-- write log before update
				
				SET @xml = (
						SELECT  
							apt.SportType				AS '@s'
							,apt.BetType				AS '@b'
							,apt.IsLive					AS '@i'
							,apt.PresetPositionTaking	AS '@p'
							,apt.MaxPositionTaking		AS '@m'
						FROM AgentPositionTaking3rd AS apt WITH (NOLOCK)
							INNER JOIN @TablePositiongTaking AS tpt
								ON apt.SportType	= tpt.SportType
								AND apt.BetType		= tpt.BetType
								AND apt.IsLive		= tpt.IsLive
						WHERE apt.AgentId			= @AgentId				
						FOR XML PATH('z')
				)

				SET @LogOldData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

				-- end write log

				IF EXISTS (
					SELECT TOP(1) *
					FROM 
						AgentPositionTaking3rd AS apt WITH (NOLOCK)
					INNER JOIN @TablePositiongTaking AS tapt
						ON apt.SportType	= tapt.SportType
						AND apt.BetType		= tapt.BetType
						AND apt.IsLive		= tapt.IsLive
					WHERE apt.AgentId = @AgentId
						AND apt.MaxPositionTaking	> tapt.MaxPositionTaking
				)
					BEGIN					

							---- Update for downline agent max less new max position taking
						UPDATE
							apt WITH (ROWLOCK, UPDLOCK)
						SET
							apt.PresetPositionTaking	= apt.PresetPositionTaking - tempData.ParentMaxPositionTaking + tempData.MaxPositionTakingAgent 
						FROM AgentPositionTaking3rd AS apt	
							INNER JOIN (					
									SELECT apt.AgentId
											,apt.SportType
											,apt.BetType
											,apt.IsLive										
											,ai.ParentId
											,tpt.MaxPositionTaking		AS MaxPositionTakingAgent
											,papt.MaxPositionTaking		AS ParentMaxPositionTaking
									FROM AgentPositionTaking3rd AS apt WITH (NOLOCK)
										INNER JOIN AgentInfo AS ai WITH (NOLOCK)
											ON apt.AgentId = ai.AgentId
										INNER JOIN AgentPositionTaking3rd AS papt WITH (NOLOCK)
											ON apt.SportType	= papt.SportType
											AND apt.BetType		= papt.BetType
											AND apt.IsLive		= papt.BetType
											AND ai.ParentId		= papt.AgentId
										INNER JOIN @TablePositiongTaking AS tpt
											ON apt.SportType	= tpt.SportType
											AND apt.BetType		= tpt.BetType
											AND apt.IsLive		= tpt.BetType
											AND apt.MaxPositionTaking <= tpt.MaxPositionTaking
											AND papt.MaxPositionTaking > tpt.MaxPositionTaking
									WHERE ai.AgentHId.IsDescendantOf(@agentHId) = 1 
										AND ai.AgentId		<> @agentId	
										AND ai.AgentLevel	<> @MAINAGENTLEVEL				
							) AS tempData
								ON apt.SportType	= tempData.SportType
								AND apt.BetType		= tempData.BetType
								AND apt.IsLive		= tempData.IsLive
								AND apt.AgentId		= tempData.AgentId							

						---- Update for main agent
						UPDATE
							apt WITH (ROWLOCK, UPDLOCK)
						SET
							apt.PresetPositionTaking	= 0
							,apt.MaxPositionTaking		= tempData.MaxPositionTakingAgent
						FROM AgentPositionTaking3rd AS apt	
							INNER JOIN (					
									SELECT apt.AgentId
											,apt.SportType
											,apt.BetType
											,apt.IsLive										
											,ai.ParentId
											,tpt.MaxPositionTaking		AS MaxPositionTakingAgent
									FROM AgentPositionTaking3rd AS apt WITH (NOLOCK)
										INNER JOIN AgentInfo AS ai WITH (NOLOCK)
											ON apt.AgentId = ai.AgentId								
										INNER JOIN @TablePositiongTaking AS tpt
											ON apt.SportType	= tpt.SportType
											AND apt.BetType		= tpt.BetType
											AND apt.IsLive		= tpt.BetType
											AND apt.MaxPositionTaking + apt.PresetPositionTaking > tpt.MaxPositionTaking									
									WHERE ai.AgentHId.IsDescendantOf(@agentHId) = 1 
										AND ai.AgentId <> @agentId
										AND ai.AgentLevel	= @MAINAGENTLEVEL					
							) AS tempData
								ON apt.SportType	= tempData.SportType
								AND apt.BetType		= tempData.BetType
								AND apt.IsLive		= tempData.IsLive
								AND apt.AgentId		= tempData.AgentId

						---- Update for downline agent max greater new max position taking
						UPDATE
							apt WITH (ROWLOCK, UPDLOCK)
						SET
							apt.PresetPositionTaking	= 0
							,apt.MaxPositionTaking		= tempData.MaxPositionTakingAgent
						FROM AgentPositionTaking3rd AS apt	
							INNER JOIN (					
									SELECT apt.AgentId
											,apt.SportType
											,apt.BetType
											,apt.IsLive										
											,ai.ParentId
											,tpt.MaxPositionTaking		AS MaxPositionTakingAgent
									FROM AgentPositionTaking3rd AS apt WITH (NOLOCK)
										INNER JOIN AgentInfo AS ai WITH (NOLOCK)
											ON apt.AgentId = ai.AgentId								
										INNER JOIN @TablePositiongTaking AS tpt
											ON apt.SportType	= tpt.SportType
											AND apt.BetType		= tpt.BetType
											AND apt.IsLive		= tpt.BetType
											AND apt.MaxPositionTaking >= tpt.MaxPositionTaking									
									WHERE ai.AgentHId.IsDescendantOf(@agentHId) = 1 
										AND ai.AgentId <> @agentId					
							) AS tempData
								ON apt.SportType	= tempData.SportType
								AND apt.BetType		= tempData.BetType
								AND apt.IsLive		= tempData.IsLive
								AND apt.AgentId		= tempData.AgentId	
					END		

				---- Update for current agent
				UPDATE 
					apt WITH (ROWLOCK, UPDLOCK)
				SET 
					apt.PresetPositionTaking	= tpt.PresetPositionTaking
					,apt.MaxPositionTaking		= tpt.MaxPositionTaking
				FROM 
					AgentPositionTaking3rd AS apt
					INNER JOIN @TablePositiongTaking AS tpt 
						ON apt.SportType	= tpt.SportType
						AND apt.BetType		= tpt.BetType
						AND apt.IsLive		= tpt.IsLive
				WHERE apt.AgentId = @AgentId

				-- write log before update
				
				SET @xml = (
						SELECT  
							tpt.SportType				AS '@s'
							,tpt.BetType				AS '@b'
							,tpt.IsLive					AS '@i'
							,tpt.PresetPositionTaking	AS '@p'
							,tpt.MaxPositionTaking		AS '@m'
						FROM @TablePositiongTaking AS tpt							
						FOR XML PATH('z')
				)

				SET @LogData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

				-- end write log
			END		 
	END	


END