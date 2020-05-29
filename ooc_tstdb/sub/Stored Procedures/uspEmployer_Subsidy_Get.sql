
CREATE PROCEDURE [sub].[uspEmployer_Subsidy_Get]
@EmployerNumber		varchar(8),
@SubsidySchemeID	int,
@StartDate			date
AS
/*	==========================================================================================
	Purpose:	Get sub.tblEmployer_Subsidy data on the basis of EmployerNumber, 
					@SubsidySchemeID and StartDate.

	13-08-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	EmployerSubsidyID,
        EmployerNumber,
		SubsidySchemeID,
		StartDate,
		EndDate,
		Amount,
		EndDeclarationPeriod
FROM	sub.tblEmployer_Subsidy
WHERE	EmployerNumber = @EmployerNumber
  AND	SubsidySchemeID = @SubsidySchemeID
  AND	StartDate = @StartDate

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_Subsidy_Get ===========================================================	*/
