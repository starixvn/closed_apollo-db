USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_UpdateDirectMemberPositionTaking]    Script Date: 9/20/2013 4:53:07 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/*
DECLARE	@return_value int,
		@ErrCode int,
		@ErrMsg nvarchar(1000)

EXEC	@return_value = [dbo].[Age_Customer_UpdatePositionTaking]
		@ActorAgentId = 206,
		@AgentId = 226,
		@CustId = 128465,
		@PositionTaking = N'<ROOT><PositionTaking SportType="1" BetType="1" IsLive="0" PT="5000" ></PositionTaking></ROOT>',		
		@Language = NULL,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT

SELECT	@ErrCode as N'@ErrCode',
		@ErrMsg as N'@ErrMsg'

SELECT	'Return Value' = @return_value

GO

*/

ALTER PROCEDURE [dbo].[Age_Agent_UpdateDirectMemberPositionTaking]
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
 * Date			: 20130412
 * Task			: Update customer position taking
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	
 * Parameters:
 * • @AgentID			: Parent agent ID
 * • @PositionTaking	: 
 *		<ROOT>
 *			<PositionTaking SportType="4" BetType="4" IsLive="1" PT="10" ></PositionTaking>
 *		</ROOT>
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	-- Check update permission
	DECLARE @hasPermission BIT	

	IF @PositionTaking <> ''
		BEGIN
			-- For write log
			DECLARE 
				@startRun		DATETIME,
				@endRun			DATETIME,
				@duration		INT,
				@logSPData		VARCHAR(5000),
				@logSPDataOld	VARCHAR(5000),
				@xml			XML,
				@CustId			INT

			SET @startRun = GETDATE()

			SELECT TOP(1) @CustId = CustId
			FROM CustInfo WITH (NOLOCK)
			WHERE AgentId = @AgentId

			CREATE TABLE #TablePositionTaking(
				SportType	SMALLINT,
				BetType		SMALLINT,
				IsLive		BIT,
				PT			SMALLINT)			

			-- For read xml
			DECLARE @DocHandler INT

			EXEC sp_xml_preparedocument @DocHandler OUTPUT, @PositionTaking

			INSERT INTO #TablePositionTaking (
				SportType,
				BetType,
				IsLive,
				PT)
			SELECT
				Data.SportType,
				Data.BetType,
				Data.IsLive,
				Data.PT
			FROM OPENXML (@DocHandler, '/ROOT/PositionTaking', 1) 
			WITH (
				SportType	SMALLINT,
				BetType		SMALLINT,
				IsLive		BIT,
				PT			SMALLINT
			) AS Data

			EXEC sp_xml_removedocument @DocHandler
			-- end read xml

			-- Validate data

			DELETE tpt
			FROM 
				#TablePositionTaking AS tpt
				INNER JOIN dbo.CustPositionTaking AS cpt WITH (NOLOCK)
				ON 	cpt.SportType	= tpt.SportType
					AND cpt.BetType	= tpt.BetType
					AND cpt.IsLive	= tpt.IsLive
			WHERE 
				cpt.PositionTaking	= tpt.PT
				AND cpt.CustId		= @CustId
				AND cpt.AgentId		= @AgentId

			IF EXISTS (	SELECT 1 FROM #TablePositionTaking )
				BEGIN
					-- write log before update
					SET @xml = (
						SELECT  
							SportType		AS '@s'
							,BetType		AS '@b'
							,IsLive			AS '@i'
							,PositionTaking	AS '@p'
						FROM dbo.CustPositionTaking WITH (NOLOCK)							
						WHERE 
							AgentId	= @AgentId
							AND CustId	= @CustId
						ORDER BY
							SportType							
							,IsLive
						FOR XML PATH('z')
					)

					SET @logSPDataOld = '<r a="' + CAST(@AgentId AS VARCHAR) + '">' + REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"') + '</r>'

					-- end write log

					---- Declare agentId
					DECLARE 
						@agentLevel		SMALLINT,
						@agentHId		HIERARCHYID,
						@agentUsername	NVARCHAR(50),
						@sportType		INT,
						@betType		INT,
						@isLive			BIT,
						@childAgentId	INT
					---- End declare

					SELECT 
						@agentLevel = AgentLevel,
						@agentHId = AgentHId,
						@agentUsername = Username
					FROM dbo.AgentInfo WITH (NOLOCK)
					WHERE AgentId = @AgentId

					---- End set value

					-- Check for direct member or indirect member					
					SELECT TOP(1) 
						@sportType	= apt.SportType 
						,@betType	= apt.BetType
						,@isLive	= apt.IsLive
					FROM 
						dbo.AgentPositionTaking AS apt WITH (NOLOCK)
						INNER JOIN #TablePositionTaking AS ptt
						ON apt.SportType	= ptt.SportType
							AND apt.BetType	= ptt.BetType
							AND apt.IsLive	= ptt.IsLive
					WHERE 
						apt.AgentId = @AgentId
						AND ptt.PT NOT BETWEEN apt.MinGivenPositionTaking AND apt.MaxGivenPositionTaking
								
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
					
					-- Get data for all line
					CREATE TABLE #TableAllLinePositionTaking (
						AgentId						INT
						,ParentAgentId				INT
						,ParentAgentLevel			SMALLINT
						,SportType					SMALLINT
						,BetType					SMALLINT
						,IsLive						BIT
						,MaxUpperPositionTaking		SMALLINT
						,MaxGivenPositionTaking		SMALLINT
						,MinGivenPositionTaking		SMALLINT
						,PositionTaking				SMALLINT
						,SumPresetDown				INT
						,DeltaMinSumDown			SMALLINT
						,MaxDeltaDown				SMALLINT
						,MemPositionTaking			SMALLINT
						,NewMaxUpperPositionTaking	SMALLINT
						,NewMaxGivenPositionTaking	SMALLINT
						,NewMinGivenPositionTaking	SMALLINT
						,NewPositionTaking			SMALLINT
						,NewSumPresetDown			INT
						,NewMemPositionTaking		SMALLINT
						,NewDeltaMinSumDown			SMALLINT
						,NewMaxDeltaDown			SMALLINT
					)

					CREATE CLUSTERED INDEX IX_C_#TableAllLinePositionTaking ON #TableAllLinePositionTaking (AgentId, ParentAgentId, ParentAgentLevel, SportType, BetType, IsLive) 

					INSERT INTO #TableAllLinePositionTaking(
						AgentId
						,ParentAgentId
						,ParentAgentLevel
						,SportType
						,BetType
						,IsLive
						,MaxUpperPositionTaking
						,MaxGivenPositionTaking
						,MinGivenPositionTaking
						,PositionTaking
						,SumPresetDown
						,MemPositionTaking
						,DeltaMinSumDown
						,MaxDeltaDown
						,NewMaxUpperPositionTaking
						,NewMaxGivenPositionTaking
						,NewMinGivenPositionTaking
						,NewPositionTaking
						,NewSumPresetDown
						,NewMemPositionTaking
						,NewDeltaMinSumDown
						,NewMaxDeltaDown
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
							,0
							,0
							,0
							,0
							,0
							,apt.MaxUpperPositionTaking
							,apt.MaxGivenPositionTaking
							,apt.MinGivenPositionTaking		
							,0
							,0
							,0
							,0
							,0
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
					WHERE ai.AgentHId.IsDescendantOf(@agentHId) = 1	 
						AND EXISTS (SELECT TOP(1) * FROM CustInfo AS ci WITH (NOLOCK) WHERE ci.AgentId = ai.AgentId)						
						AND ai.AgentId = @AgentId
				   
					UPDATE pt
					SET pt.PositionTaking		= ISNULL(pt1.MaxUpperPositionTaking,cpt.PositionTaking)	
						,pt.NewPositionTaking	= ISNULL(pt1.NewMaxUpperPositionTaking,tpt.PT)	
					FROM #TableAllLinePositionTaking AS pt 
						LEFT JOIN #TableAllLinePositionTaking AS pt1 
							ON pt.AgentId			= pt1.AgentId
							AND pt.ParentAgentLevel	= pt1.ParentAgentLevel - 1
							AND pt.SportType		= pt1.SportType
							AND pt.BetType			= pt1.BetType
							AND pt.IsLive			= pt1.IsLive
						INNER JOIN #TablePositionTaking AS tpt
							ON pt.SportType			= tpt.SportType
							AND pt.BetType			= tpt.BetType
							AND pt.IsLive			= tpt.IsLive
						INNER JOIN CustPositionTaking AS cpt WITH (NOLOCK)
							ON pt.SportType			= cpt.SportType
							AND pt.BetType			= cpt.BetType
							AND pt.IsLive			= cpt.IsLive			
						INNER JOIN CustInfo AS ci WITH (NOLOCK)
							ON cpt.CustId			= ci.CustId
							AND cpt.AgentId			= pt.AgentId
					WHERE ci.AgentId	= pt.AgentId 
						AND ci.CustId 	= @CustId
					
					UPDATE pt
					SET pt.SumPresetDown			= temp.SumPresetDownLine	
						,pt.NewSumPresetDown		= temp.NewPresetSumDownLine	
					FROM #TableAllLinePositionTaking AS pt
						INNER JOIN (
							SELECT 	
									pt.AgentId
									,pt.ParentAgentId
									,pt.SportType
									,pt.BetType
									,pt.IsLive
									,SUM(ISNULL(pt1.PositionTaking,0))		AS SumPresetDownLine
									,SUM(ISNULL(pt1.NewPositionTaking,0))	AS NewPresetSumDownLine
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

					UPDATE #TableAllLinePositionTaking 
					SET DeltaMinSumdown		= MinGivenPositionTaking	- SumPresetDown
						,NewDeltaMinSumDown = NewMinGivenPositionTaking	- NewSumPresetDown

					UPDATE pt
					SET pt.MaxDeltaDown			= CASE WHEN temp.MaxDeltaDownline < 0 THEN 0 ELSE temp.MaxDeltaDownline END	
						,pt.NewMaxDeltaDown		= CASE WHEN temp.NewMaxDeltaDownline < 0 THEN 0 ELSE temp.NewMaxDeltaDownline END							
					FROM #TableAllLinePositionTaking AS pt
						INNER JOIN (
							SELECT 	
									pt.AgentId
									,pt.ParentAgentId
									,pt.SportType
									,pt.BetType
									,pt.IsLive
									,MAX(ISNULL(pt1.DeltaMinSumDown,0))		AS MaxDeltaDownline
									,MAX(ISNULL(pt1.NewDeltaMinSumDown,0))	AS NewMaxDeltaDownline
							FROM #TableAllLinePositionTaking AS pt 
								LEFT JOIN #TableAllLinePositionTaking AS pt1 
									ON pt.AgentId			= pt1.AgentId
									AND pt.ParentAgentLevel	< pt1.ParentAgentLevel
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

					UPDATE pt
					SET pt.MemPositionTaking		= CASE WHEN pt.MinGivenPositionTaking - (pt.SumPresetDown + pt.MaxDeltaDown) + pt.PositionTaking > pt.PositionTaking 
															THEN pt.MinGivenPositionTaking - (pt.SumPresetDown + pt.MaxDeltaDown) + pt.PositionTaking
															ELSE pt.PositionTaking
														END	
						,pt.NewMemPositionTaking	= CASE WHEN pt.NewMinGivenPositionTaking - (pt.NewSumPresetDown + pt.NewMaxDeltaDown) + pt.NewPositionTaking > pt.NewPositionTaking 
															THEN pt.NewMinGivenPositionTaking - (pt.NewSumPresetDown + pt.NewMaxDeltaDown) + pt.NewPositionTaking 
															ELSE pt.NewPositionTaking
														END	
					FROM #TableAllLinePositionTaking AS pt 						
					
					DELETE pt
					FROM #TableAllLinePositionTaking AS pt
					WHERE pt.MemPositionTaking = pt.NewMemPositionTaking			
																							 
					UPDATE cpt 
					SET	cpt.PositionTaking = tapt.NewMemPositionTaking
					FROM CustPositionTaking AS cpt WITH (ROWLOCK, UPDLOCK)
						INNER JOIN CustInfo AS ci WITH (NOLOCK)
							ON cpt.CustId = ci.CustId
						INNER JOIN #TableAllLinePositionTaking AS tapt
							ON ci.AgentId		= tapt.AgentId
							AND cpt.SportType	= tapt.SportType
							AND cpt.BetType		= tapt.BetType
							AND cpt.IsLive		= tapt.IsLive
							AND cpt.AgentId		= tapt.ParentAgentId															
					-- End edit position taking on member 	

					DROP TABLE #TableAllLinePositionTaking

					SET @xml = (
						SELECT 
							SportType	AS '@s',
							BetType		AS '@b',
							IsLive		AS '@i',
							PT			AS '@p'
						FROM #TablePositionTaking
						ORDER BY 
							SportType,
							IsLive
						FOR XML PATH('z')
					)

					SET @logSPData = '<r a="' + @agentUsername + '">' + REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"') + '</r>'

					SET @endRun	= GETDATE()  
					SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 

					IF @@ERROR = 0
						BEGIN TRY
							EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
								@UserId		= @ActorAgentId,
								@AdminId	= @AdminId,
								@SPName		= 'Age_Agent_UpdateDirectMemberPositionTaking',
								@LogDate	= @startRun,
								@AgentId	= @AgentId,
								@Duration	= @Duration,
								@Data		= @logSPData,
								@OldData	= @logSPDataOld
						END TRY
						BEGIN CATCH
							EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
								@UserId		= @ActorAgentId,
								@AdminId	= @AdminId,
								@SPName		= 'Age_Agent_UpdateDirectMemberPositionTaking',
								@LogDate	= @startRun,
								@AgentId	= @AgentId,
								@Duration	= @Duration,
								@Data		= @logSPData,
								@OldData	= @logSPDataOld
						END CATCH
				END

			DROP TABLE #TablePositionTaking
		END
END

