
CREATE PROCEDURE [sub].[uspEmployer_List]
AS
/*	==========================================================================================
	Purpose:	Select all data of table sub.tblEmployer.

	19-11-2018	Sander van Houten		Added Ascription (OTIBSUB-98).
	20-07-2018	Jaap van Assenbergh		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

	SELECT
			EmployerNumber,
			EmployerName,
			Email,
			IBAN,
			Ascription,
			CoC,
			Phone,
			BusinessAddressStreet,
			BusinessAddressHousenumber,
			BusinessAddressZipcode,
			BusinessAddressCity,
			BusinessAddressCountrycode,
			PostalAddressStreet,
			PostalAddressHousenumber,
			PostalAddressZipcode,
			PostalAddressCity,
			PostalAddressCountrycode,
			StartDateMembership,
			EndDateMembership
	FROM	sub.tblEmployer
	ORDER BY EmployerName

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspEmployer_List ===================================================================	*/
