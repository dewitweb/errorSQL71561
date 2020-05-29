
CREATE PROCEDURE [stip].[uspDeclaration_Get]
@DeclarationID	int
AS
/*	==========================================================================================
	Purpose: 	Get data from stip.tblDeclaration on basis of DeclarationID.

	01-05-2019	Jaap van Assenbergh	Inital version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT	DeclarationID,
		EmployerNumber,
		SubsidySchemeID,
		DeclarationDate,
		InstituteID,
		StartDate,
		EndDate,
		DeclarationAmount,
		ApprovedAmount,
		DeclarationStatus,
		StatusReason,
		InternalMemo,
		EducationID,
		EducationName, 
		NominalDuration, 
		DiplomaDate, 
		DiplomaCheckedByUserID, 
		DiplomaCheckedDate, 
		TerminationDate, 
		TerminationReason, 
		LastMentorID, 
		LastMentorFullName	
FROM	stip.viewDeclaration
WHERE	DeclarationID = @DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspDeclaration_Get ====================================================================	*/
