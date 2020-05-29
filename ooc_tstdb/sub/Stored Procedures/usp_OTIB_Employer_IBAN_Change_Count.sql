
CREATE PROCEDURE [sub].[usp_OTIB_Employer_IBAN_Change_Count] 
AS
/*	==========================================================================================
	Purpose:	List all submitted IBAN changes which are not handled fully yet.

	19-02-2019	Jaap van Assenbergh		Eerste versie
				OTIBSUB-794 Stored procedure die totaal aantal openstaande IBAN wijzigingen 
				teruggeeft
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

BEGIN 
	SELECT	COUNT(eic.IBANChangeID)	ChangeCount
	FROM	sub.tblEmployer_IBAN_Change eic
	INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = eic.EmployerNumber
	WHERE   eic.ChangeStatus IN ('0000', '0001')
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_IBAN_Change_Attachment_List ===========================================	*/
