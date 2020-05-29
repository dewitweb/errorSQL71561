CREATE PROCEDURE [sub].[uspEmployer_IBAN_Change_List] 
@EmployerNumber	varchar(6)
AS
/*	==========================================================================================
	Purpose:	List all submitted IBAN changes which are not handled fully yet.

	19-11-2019	Sander van Houten	OTIBSUB-1718	Added ChangeStatus, ReturnToEmployerReason
                                        and CanModify.
	18-09-2019	Jaap van Assenbergh	OTIBSUB-98      Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* testdata
DECLARE @EmployerNumber varchar(6) = '074100'
--*/

SELECT	IBANChangeID,
		IBAN_New,
		Creation_DateTime,
		StartDate,
        ChangeStatus,
        ReturnToEmployerReason,
        CAST(
                CASE ChangeStatus
                    WHEN '0000' THEN 1
                    WHEN '0005' THEN 1
                    ELSE 0
                END
            AS bit )    AS CanModify
FROM	sub.tblEmployer_IBAN_Change
WHERE	EmployerNumber = @EmployerNumber 
AND		ChangeStatus IN ('0000', '0001', '0005')
ORDER BY 
        StartDate, 
        IBANChangeID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_IBAN_Change_List ======================================================	*/
