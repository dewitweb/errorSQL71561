CREATE PROCEDURE [auth].[uspRole_List]
AS
/*	==========================================================================================
	Purpose:	Get all records from the table tblRole

	08-10-2019	Sander van Houten	OTIBSUB-1446    Added field IsSubsidyschemeDependent.
	01-05-2018	Sander van Houten	Conversion from uspGebruikersGroep_List for new datamodel.
	05-03-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT
		RoleID,
		RoleName,
		RoleDescription,
		Abbreviation,
		ApplicationID,
        IsSubsidySchemeDependent
FROM	auth.tblRole
ORDER BY RoleDescription

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspRole_List =====================================================================	*/
