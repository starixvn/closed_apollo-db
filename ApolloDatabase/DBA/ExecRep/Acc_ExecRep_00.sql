ALTER PROCEDURE [dbo].[Acc_ExecRep_00] 
	@AgentId	INT, 
	@Permission	VARCHAR(MAX),
	@IsApplyDownline SMALLINT = 0
AS 
/*
Created by:Sophia
Date: 20131113
Task:	Called by [Age_AgentUser_AssignFunction_xtest]
		Update Downline permission 
DB:  SVRTXN.CustDB
Revisions:
    
 */
SET NOCOUNT ON 

---- Check if TransDB then return
	IF (select DB_NAME(db_id()))  = 'TransDB'  
	RETURN

	DECLARE @FunctionPolicy TABLE (FunctionId SMALLINT, Policy TINYINT)
	DECLARE @AgentHId		HIERARCHYID

---- For read xml
	DECLARE @DocHandler INT

	EXEC sp_xml_preparedocument @DocHandler OUTPUT, @Permission

	INSERT INTO @FunctionPolicy (
		FunctionId
		,Policy)
	SELECT
		Data.FunctionId,
		Data.Policy
	FROM OPENXML (@DocHandler, '/ROOT/FunctionPolicy',1) 
	WITH (			
		FunctionId		SMALLINT,
		Policy			TINYINT
	) AS Data

	EXEC sp_xml_removedocument @DocHandler
---- end read xml


	SELECT @AgentHId = AgentHId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId

	  
---Update downline
		IF @IsApplyDownline = -1 ---- Uncheck Permission
		BEGIN 
			UPDATE auf
			SET auf.Policy =  f.Policy								 				 
			FROM AgentUserFunction AS auf WITH (ROWLOCK, UPDLOCK)
				INNER JOIN AgentInfo AS ai WITH (NOLOCK)
					ON auf.AgentId = ai.AgentId
				INNER JOIN @FunctionPolicy AS f
					ON auf.FunctionId = f.FunctionId
			WHERE	ai.AgentHId.IsDescendantOf(@AgentHId) = 1	
					AND auf.Policy > f.Policy
			OPTION(RECOMPILE)
		END
		ELSE  --- Check Permission 
		BEGIN 		
			UPDATE auf
			SET auf.Policy = CASE WHEN auf.AgentUserId = auf.AgentId  ---Agents
							THEN CASE WHEN @IsApplyDownline = 1 AND auf.Policy < f.Policy THEN  f.Policy 
									  WHEN @IsApplyDownline = 0 AND auf.Policy < f.Policy THEN  auf.Policy 
									  WHEN auf.Policy > f.Policy THEN f.Policy
								  ELSE auf.Policy 
								  END 
							ELSE		---Shadows
							CASE WHEN @IsApplyDownline = 1 AND auf.Policy < f.Policy THEN 1
								 WHEN @IsApplyDownline = 0 AND auf.Policy < f.Policy THEN auf.Policy 
								 WHEN auf.Policy > f.Policy THEN f.Policy
								 ELSE auf.Policy 
								 END 
							END 		 
			FROM AgentUserFunction AS auf WITH (ROWLOCK, UPDLOCK)
				INNER JOIN AgentInfo AS ai WITH (NOLOCK)
					ON auf.AgentId = ai.AgentId
				INNER JOIN @FunctionPolicy AS f
					ON auf.FunctionId = f.FunctionId
			WHERE	ai.AgentHId.IsDescendantOf(@AgentHId) = 1	
			OPTION(RECOMPILE)		 
		END	
 