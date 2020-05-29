
CREATE PROCEDURE [sub].[uspEmployer_Get]
@EmployerNumber	varchar(6)
AS
/*	==========================================================================================
	Purpose:	Select specific data from sub.tblEmployer on the basis of EmployerNumber.

	19-11-2018	Sander van Houten		Added Ascription (OTIBSUB-98).
	20-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			e.EmployerNumber,
			e.EmployerName,
			e.Email,
			e.IBAN,
			e.Ascription,
			e.CoC,
			e.Phone,
			e.BusinessAddressStreet,
			e.BusinessAddressHousenumber,
			e.BusinessAddressZipcode,
			e.BusinessAddressCity,
			e.BusinessAddressCountrycode,
			e.PostalAddressStreet,
			e.PostalAddressHousenumber,
			e.PostalAddressZipcode,
			e.PostalAddressCity,
			e.PostalAddressCountrycode,
			e.StartDateMembership,
			e.EndDateMembership,
			(
				SELECT	COUNT(ee.EmployeeNumber) 
				FROM	sub.tblEmployer_Employee ee				
				WHERE	ee.EmployerNumber = e.EmployerNumber
			)	NumberOfEmployees
	FROM	sub.tblEmployer e
	WHERE	e.EmployerNumber = @EmployerNumber

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspEmployer_Get ========================================================================	*/
