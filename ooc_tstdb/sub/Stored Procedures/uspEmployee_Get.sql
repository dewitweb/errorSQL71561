
CREATE PROCEDURE [sub].[uspEmployee_Get]
	@EmployeeNumber	varchar(8)
AS
/*	==========================================================================================
	20-07-2018	Jaap van Assenbergh
				Ophalen gegevens uit sub.tblEmployee op basis van EmployeeNumber
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			EmployeeNumber,
			FullName AS EmployeeName,
			Email,
			IBAN
	FROM	sub.tblEmployee
	WHERE	EmployeeNumber = @EmployeeNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspEmployee_Get ========================================================================	*/
