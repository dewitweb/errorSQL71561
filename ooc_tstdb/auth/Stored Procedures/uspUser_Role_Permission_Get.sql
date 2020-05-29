CREATE PROCEDURE [auth].[uspUser_Role_Permission_Get]
@UserID		int
AS
/*	==========================================================================================
	Purpose:	Get all roles and permissions linked to a specific user.

    08-10-2019	Sander van Houten	OTIBSUB-1446    Added fields IsSubsidySchemeDependent and
                                                        SubsidySchemeID.
	12-12-2018	Sander van Houten	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @UserID		int = 7
--  */

SELECT
		usr.UserID,
		usr.Fullname,
		rol.RoleID,
		rol.RoleName,
		rol.RoleDescription,
		rol.Abbreviation,
		CASE ISNULL(uro.RoleID, 0) WHEN 0 THEN 0 ELSE 1 END			AS RoleLinked,
		prm.PermissionID,
		prm.PermissionCode,
		prm.PermissionDescription_NL								AS PermissionDescription,
		CASE ISNULL(rop.PermissionID, 0) WHEN 0 THEN 0 ELSE 1 END	AS PermissionLinked,
        rol.IsSubsidySchemeDependent,
        CASE rol.IsSubsidySchemeDependent
            WHEN 0 THEN NULL
            ELSE ISNULL(STUFF(( SELECT  ','+ CAST(urs.SubsidySchemeID AS varchar(18))
                                FROM    auth.tblUser_Role_SubsidyScheme urs
                                WHERE   urs.UserID = uro.UserID
                                AND     urs.RoleID = uro.RoleID
                                GROUP BY 
                                        urs.SubsidySchemeID
                                ORDER BY 
                                        urs.SubsidySchemeID
                                FOR XML PATH('')
                              ), 1, 1, ''
                             ), ''
                        )
        END                                                         AS SubsidySchemeID
FROM	auth.tblUser usr
CROSS JOIN auth.tblRole rol
LEFT JOIN auth.tblUser_Role uro ON uro.UserID = usr.UserID AND uro.RoleID = rol.RoleID
INNER JOIN auth.tblRole_Permission rop ON rop.RoleID = rol.RoleID
INNER JOIN auth.tblPermission prm ON prm.PermissionID = rop.PermissionID
WHERE	usr.UserID = @UserID
ORDER BY
		usr.UserID,
		rol.RoleID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspUser_Role_Permission_Get ======================================================	*/
