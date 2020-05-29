

CREATE procedure [ait].[uspExecutedProcedure_Cleanup] 
AS
/*	==========================================================================================
	Purpose: 	CleanUp ait.tblExecutedProcedure
				Used in Job: OTIB-DS Daily Controls

	30-09-2019	Jaap van Assenbergh	OTIBSUB-1599 Opschonen ait.tblExecutedProcedure
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DELETE
FROM	ait.tblExecutedProcedure
WHERE	CAST(StartTime as date) <= CAST(DATEADD(MONTH, -3, GETDATE()) as date)

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

