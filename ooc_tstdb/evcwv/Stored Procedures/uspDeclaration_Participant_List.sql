
CREATE PROCEDURE [evcwv].[uspDeclaration_Participant_List]
@DeclarationID	int
AS
/*	==========================================================================================
	Purpose:	Get Participant by Declaration

	04-11-2019	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		evcwv.DeclarationID,
		evcwv.ParticipantID,
		e.FullName + CASE WHEN e.DateOfBirth IS NULL 
						THEN ''
						ELSE ' (' + CONVERT(varchar(10), e.DateOfBirth, 105) + ')'
					 END	AS EmployeeName
FROM	evcwv.viewDeclaration evcwv
INNER JOIN	evcwv.tblParticipant par 
		ON	par.ParticipantID = evcwv.ParticipantID
INNER JOIN sub.tblEmployee e 
		ON	e.EmployeeNumber = par.EmployeeNumber
WHERE	evcwv.DeclarationID = @DeclarationID
UNION ALL
SELECT
		evcwv.DeclarationID,
		evcwv.ParticipantID,
		par.FullName + CASE WHEN par.DateOfBirth IS NULL 
						THEN ''
						ELSE ' (' + CONVERT(varchar(10), par.DateOfBirth, 105) + ')'
					 END	AS EmployeeName
FROM	evcwv.viewDeclaration evcwv
INNER JOIN	evcwv.tblParticipant par 
		ON	par.ParticipantID = evcwv.ParticipantID
WHERE	evcwv.DeclarationID = @DeclarationID
AND		COALESCE(evcwv.EmployeeNumber, '')  = ''


EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Employee_List =======================================================	*/
