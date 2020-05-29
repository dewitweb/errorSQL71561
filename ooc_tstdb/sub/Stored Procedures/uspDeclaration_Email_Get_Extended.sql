
CREATE PROCEDURE [sub].[uspDeclaration_Email_Get_Extended]
@DeclarationID	int,
@UserID			int
AS
/*	==========================================================================================
	Purpose:	Get data from sub.tblDeclaration_Email on the basis of DeclarationID
				supplemented with extra information.

	28-05-2019	Sander van Houten		Added UserName of actual sender (OTIBSUB-305).
	27-09-2018	Sander van Houten		Added UserName (OTIBSUB-305).
	02-08-2018	Sander van Houten		Initial version (OTIBSUB-85).
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

SELECT 
		dem.EmailID,
		dem.DeclarationID,
		dem.EmailDate,
		dem.EmailSubject,
		dem.EmailBody,
		dem.Direction,
		dem.HandledDate,
		( SELECT	AttachmentID, 
					OriginalFileName
		  FROM sub.tblDeclarationEmail_Attachment
		  WHERE EmailID = dem.EmailID
		  FOR XML PATH)								AS Attachments,
		deu.HandledDate								AS UserHasReadEmailOn,
		usr.Fullname								AS UserName,
		sender.Fullname								AS UserNameSender
FROM	sub.tblDeclaration_Email dem
	LEFT JOIN sub.tblDeclaration_Email_User deu
		   ON deu.EmailID = dem.EmailID
		  AND deu.UserID = @UserID
	LEFT JOIN auth.tblUser usr
		   ON usr.UserID = deu.UserID
	LEFT JOIN his.tblHistory hst
		   ON hst.TableName = 'sub.tblDeclaration_Email'
		  AND hst.KeyID = dem.EmailID
		  AND hst.OldValue IS NULL
	LEFT JOIN auth.tblUser sender
		   ON sender.UserID = hst.UserID
WHERE	dem.DeclarationID = @DeclarationID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== uspDeclaration_Email_Get_Extended =====================================================	*/
