
CREATE PROCEDURE [sub].[uspDeclaration_Email_List_Outbox]
AS
/*	==========================================================================================
	Purpose:	Select input for e-mail sending by Windows service.

	Note:		

	29-03-2019	Sander van Houten	OTIBSUB-891 Use viewEmployerEmail instead of tblEmployer.
	27-07-2018	Jaap van Assenbergh
				Ophalen lijst uit sub.tblDeclaration_Email_Outbox
	==========================================================================================	*/

--DECLARE @ExecutedProcedureID int = 0
--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE	@RecipientOverride	varchar(100),
		@LinkURL varchar(250),
		@Email varchar(250)

SELECT	@RecipientOverride = SettingValue
FROM	eml.tblEmailSetting
WHERE	SettingName = 'RecipientOverride'

SELECT  DISTINCT
		de.EmailID,
		de.DeclarationID,
		CASE 
			WHEN ISNULL(@RecipientOverride, '') <> '' THEN @RecipientOverride 
			ELSE e.Email
		END AS Email,
		de.EmailDate,
		de.EmailSubject,
		de.EmailBody,
		de.Direction,
		de.HandledDate
FROM	sub.tblDeclaration_Email de
INNER JOIN sub.tblDeclaration d ON d.DeclarationID = de.DeclarationID
INNER JOIN sub.viewEmployerEmail e ON e.EmployerNumber = d.EmployerNumber
WHERE	de.HandledDate IS NULL
ORDER BY de.EmailDate desc

--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspDeclaration_Email_List_Outbox ==================================================	*/
