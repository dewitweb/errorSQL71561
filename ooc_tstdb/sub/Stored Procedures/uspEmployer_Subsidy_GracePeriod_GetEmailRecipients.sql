
CREATE PROCEDURE [sub].[uspEmployer_Subsidy_GracePeriod_GetEmailRecipients]
AS
/*	==========================================================================================
	Purpose: 	Get all IDs for users that have the permission to receive an e-mail with the 
                message to handle a request for a GracePeriod.

	14-01-2020	Sander van Houten	OTIBSUB-1827    Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT  DISTINCT
		UserID
FROM	auth.tblPermission prm
INNER JOIN auth.tblRole_Permission rop ON rop.PermissionID = prm.PermissionID
INNER JOIN auth.tblRole rol ON rol.RoleID = rop.RoleID
INNER JOIN auth.tblUser_Role uro ON uro.RoleID = rol.RoleID
WHERE	prm.PermissionCode = 'otib-grace-period-emailnotification'

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspEmployer_Subsidy_GracePeriod_GetEmailRecipients ====================================	*/
