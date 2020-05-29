
CREATE PROCEDURE [auth].[uspRole_Get]
@RoleID	int
AS
/*	==========================================================================================
	Purpose:	Get a record from the table tblRole

	08-10-2019	Sander van Houten	OTIBSUB-1446    Added field IsSubsidySchemeDependent.
	01-05-2018	Sander van Houten	Conversion from uspGebruikersGroep_Get for new datamodel.
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
WHERE	RoleID = @RoleID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspRole_Get ======================================================================	*/
