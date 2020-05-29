
CREATE PROCEDURE sub.uspInstitute_List
AS
/*	==========================================================================================
	25-07-2018	Jaap van Assenbergh
				Ophalen lijst uit sub.tblInstitute
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			InstituteID,
			InstituteName
	FROM	sub.tblInstitute
	ORDER BY InstituteName

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspInstitute_List ==================================================================	*/
