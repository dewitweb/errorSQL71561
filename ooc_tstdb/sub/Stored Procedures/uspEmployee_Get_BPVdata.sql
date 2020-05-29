CREATE PROCEDURE [sub].[uspEmployee_Get_BPVdata]
@EmployeeNumber		varchar(8)
AS
/*	==========================================================================================
	Purpose:	List all BPV data from Horus for an employee.

	16-08-2019	Sander van Houten		OTIBSUB-1176	Use hrs.viewBPV instead of hrs.tblBPV.
	29-05-2019	Jaap van Assenbergh		OTIBSUB-1132	Definition of 'Active BPV-s'.
	27-11-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	EmployeeNumber,
		StartDate,
		EndDate
FROM	hrs.viewBPV
WHERE	EmployeeNumber = @EmployeeNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployee_Get_BPVdata ===========================================================	*/
