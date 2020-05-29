CREATE PROCEDURE [auth].[uspUser_Role_Permission_Get_ActiveOnly]
@UserID     int
AS
/*	==========================================================================================
	Puspose:	Get all roles and permissions linked to a specific user.

    08-10-2019	Sander van Houten	OTIBSUB-1446    Added fields IsSubsidySchemeDependent and
                                                        SubsidySchemeID.
	02-01-2019	Sander van Houten	Initial version
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @UserID		int = 7
--  */

SELECT
		ur.UserID,
		ur.RoleID,
		prm.PermissionID,
		prm.PermissionCode,
		prm.PermissionDescription_NL	AS PermissionDescription,
        rol.IsSubsidySchemeDependent,
        CASE rol.IsSubsidySchemeDependent
            WHEN 0 THEN NULL
            ELSE ISNULL(STUFF(( SELECT  ','+ CAST(urs.SubsidySchemeID AS varchar(18))
                                FROM    auth.tblUser_Role_SubsidyScheme urs
                                WHERE   urs.UserID = ur.UserID
                                AND     urs.RoleID = ur.RoleID
                                GROUP BY 
                                        urs.SubsidySchemeID
                                ORDER BY 
                                        urs.SubsidySchemeID
                                FOR XML PATH('')
                              ), 1, 1, ''
                             ), ''
                        )
        END                             AS SubsidySchemeID
FROM	(
			SELECT	uro.UserID,
					CASE WHEN uro.RoleID = 1 
							THEN
								CASE WHEN 
										(
											SELECT	COUNT(uv.UserID)
											FROM	auth.tblUserValidation uv
											WHERE	uv.UserID = uro.UserID
											AND		0 NOT IN (ContactDetailsCheck, AgreementCheck, EmailCheck)
										) = 0						
									THEN 4 
									ELSE uro.RoleID 
								END
							ELSE uro.RoleID 
					END                 AS RoleID
			FROM	auth.tblUser_Role uro
			WHERE	uro.UserID = @UserID
		) ur
INNER JOIN auth.tblRole rol ON rol.RoleID = ur.RoleID
INNER JOIN auth.tblRole_Permission rop ON rop.RoleID = ur.RoleID
INNER JOIN auth.tblPermission prm ON prm.PermissionID = rop.PermissionID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspUser_Role_Permission_Get_ActiveOnly ===========================================	*/
