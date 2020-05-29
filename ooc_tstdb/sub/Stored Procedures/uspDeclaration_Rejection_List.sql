CREATE PROCEDURE [sub].[uspDeclaration_Rejection_List]
@DeclarationID		int,
@UserID				int
AS
/*	==========================================================================================
	Purpose:	Lists all rejection reasons for rejected declarations.

	17-12-2019	Jaap van Assenbergh	OTIBSUB-1780	Melding Reden: Conversie declaratiestatus 
													OTIBSUB-1539 niet tonen
	08-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	24-07-2019	Jaap van Assenbergh OTIBSUB-1357	Mededelingen status voor werkgever zichtbaar.
	28-05-2019	Sander van Houten	OTIBSUB-1127	Added filter on DeclarationStatus.
	26-04-2019	Jaap van Assenbergh OTIBSUB-1028	Handmatige reden van afkeur tonen aan werkgever.
	27-07-2018	Jaap van Assenbergh Ophalen lijst uit sub.tblDeclaration_Rejection
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*  Testdata.
DECLARE @DeclarationID		int = 412740,
        @UserID				int = 7
--  */

DECLARE @OTIB_User AS bit = 0

IF EXISTS ( SELECT 1 FROM auth.tblUser_Role WHERE UserID = @UserID AND RoleID IN (2))
BEGIN
	SET @OTIB_User = 1
END

SELECT 
        sub1.DeclarationID,
		sub1.RejectionReason,
		sub1.RejectionDateTime,
		sub1.RejectionXML,
		sub1.SortOrder
FROM (
        SELECT  DISTINCT
                der.DeclarationID,
                der.RejectionReason,
                der.RejectionDateTime,
                CAST(der.RejectionXML AS varchar(max))  AS RejectionXML,
                asr.SortOrder
        FROM	sub.tblDeclaration d
        INNER JOIN sub.tblDeclaration_Partition dep
        ON      dep.DeclarationID = d.DeclarationID
        INNER JOIN sub.tblDeclaration_Rejection der
        ON		der.DeclarationID = d.DeclarationID
        INNER JOIN sub.tblApplicationSetting asr 
        ON		asr.SettingName = 'RejectionReason'
        AND		asr.SettingCode = der.RejectionReason 
        WHERE	der.DeclarationID = @DeclarationID
        AND		dep.PartitionStatus IN ('0005', '0007', '0017')
        AND		(
                    (
                        @OTIB_User = 1
                    )
                OR	(	
                        @OTIB_User = 0
                    AND	der.RejectionReason <> '0005'
                    )
                )

        UNION ALL

        SELECT	DISTINCT
                d.DeclarationID,
                '0000'  AS RejectionReason,
                (
                    SELECT	MAX(h.LogDate)
                    FROM	his.tblHistory h
                    WHERE	h.TableName = 'sub.tblDeclaration_Partition'
                    AND		h.KeyID = CAST(dep.PartitionID AS varchar(18))
                    AND		h.NewValue.value('(/row/PartitionStatus)[1]', 'varchar(max)') = '0007'
                )       AS RejectionDateTime, 
                CAST(
                        (
                            SELECT	dsr.StatusReason
                            FROM	sub.tblDeclaration dsr
                            WHERE	dsr.DeclarationID = d.DeclarationID
                            FOR XML PATH('RejectionByOTIB'), ROOT('Rejection')
                        )
                AS varchar(max)
                    )       AS RejectionXML,
                0       AS SortOrder
        FROM	sub.tblDeclaration d
        INNER JOIN sub.tblDeclaration_Partition dep
        ON      dep.DeclarationID = d.DeclarationID
        WHERE	d.DeclarationID = @DeclarationID
        AND		d.StatusReason NOT LIKE '* %'
        AND		d.StatusReason <> 'Automatische controle'
        AND		dep.PartitionStatus IN ('0005', '0007', '0017')
		AND		d.StatusReason <> 'Conversie declaratiestatus OTIBSUB-1539'
     ) AS sub1
ORDER BY 
        sub1.SortOrder,
        sub1.RejectionReason

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Rejection_List =====================================================	*/
