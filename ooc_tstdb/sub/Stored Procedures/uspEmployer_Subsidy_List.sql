
CREATE PROCEDURE [sub].[uspEmployer_Subsidy_List]
@EmployerNumber		varchar(8)
AS
/*	==========================================================================================
	Purpose:	List all scholingbudgets on the basis of EmployerNumber.

	15-10-2018	Jaap van Assenbergh		SubsidyYear

	05-10-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	EmployerSubsidyID,
		EmployerNumber,
		SubsidySchemeID,
        StartDate,
		EndDate,
		Amount,
		CASE 
			WHEN YEAR(StartDate) = YEAR(EndDate) 
				THEN CAST(YEAR(StartDate) as char(4))
			ELSE CAST(YEAR(StartDate) as char(4)) + '/' + CAST(YEAR(EndDate) as char(4))
		END as SubsidyYear,
		EndDeclarationPeriod,
		ChangeReason
FROM	sub.tblEmployer_Subsidy
WHERE	EmployerNumber = @EmployerNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_Subsidy_List ==========================================================	*/
