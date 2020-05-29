


CREATE PROCEDURE [ait].[uspExecutedProcedure_List]
@ShowNotUsed bit = 0
AS
/*	==========================================================================================
	11-12-2018	Jaap van Assenbergh
				Overzicht uitgevoerde procedures
	==========================================================================================	*/

SELECT	sch.name + '.' + p.name ProcName,
		COUNT(ExecutedProcedureID) TimesExecuted, 
		MIN(Duration) Minimum, 
		MAX(Duration) Maximum, 
		AVG(Duration) Average,
		SUM(Duration) Total
FROM	sys.procedures p
INNER JOIN sys.schemas sch ON sch.schema_id = p.schema_id
LEFT JOIN
		(
			SELECT	ObjectID, ExecutedProcedureID, DATEDIFF(ms, StartTime, StopTime) Duration
			FROM	ait.tblExecutedProcedure ep
		) exproc ON exproc.ObjectID = p.object_id
WHERE	'T'= CASE	WHEN @ShowNotUsed = 1 
						THEN 'T' 
					ELSE 
					CASE	WHEN exproc.ObjectID IS NOT NULL 
						THEN 'T'
					END
			END
GROUP BY sch.name + '.' + p.name
ORDER BY SUM(Duration), sch.name + '.' + p.name

--SELECT  Executions, 
--		obj_ID,
--		sch_Name, 
--		obj_Name,
--		MilSec,
--		MilSec/Executions [Avg],
--		[Min],
--		[Max]
--FROM
--		(
--			SELECT  COUNT([ExecutedProcedureID]) Executions, 
--					[ObjectID] obj_ID,
--					OBJECT_SCHEMA_NAME(OBJECTID) sch_Name, 
--					OBJECT_NAME([ObjectID]) obj_Name,
--					SUM(DATEDIFF(MILLISECOND, [StartTime], [StopTime])) MilSec,
--					MIN(DATEDIFF(MILLISECOND, [StartTime], [StopTime])) [Min],
--					MAX(DATEDIFF(MILLISECOND, [StartTime], [StopTime])) [Max]
--			FROM	[ait].[tblExecutedProcedure]
--			GROUP BY	OBJECT_SCHEMA_NAME(OBJECTID), 
--						OBJECT_NAME([ObjectID]), 
--						[ObjectID]
--		) a
--ORDER BY 6
