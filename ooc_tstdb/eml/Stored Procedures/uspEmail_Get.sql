
CREATE PROCEDURE [eml].[uspEmail_Get]
@EmailID	int
AS
/*	==========================================================================================
	Purpose:	Get e-mail specifics from eml.tblEmail on basis of EmailID.

	27-11-2018	Sander van Houten		Implemented recipient override (OTIBSUB-504).
	05-10-2018	Sander van Houten		Initial version.
	==========================================================================================	*/

--DECLARE @ExecutedProcedureID int = 0
--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata
DECLARE	@EmailID	int = 88
--*/

DECLARE	@RecipientOverride	varchar(100),
		@EmailHeaders		xml = '<empty/>'

-- Get Recipient override.
SELECT	@RecipientOverride = SettingValue
FROM	eml.tblEmailSetting
WHERE	SettingName = 'RecipientOverride'

-- Get EmailHeaders from e-mail record.
SELECT	@EmailHeaders = eml.EmailHeaders
FROM	eml.tblEmail eml
WHERE	eml.EmailID = @EmailID

-- If there is a recipient override active, alter the EmailHeaders.
IF ISNULL(@RecipientOverride, '') <> '' 
BEGIN
	-- First remove the optional Bcc node.
	SET	@EmailHeaders.modify('delete /headers/*[4]')

	-- Then remove the optional Cc node.
	SET	@EmailHeaders.modify('delete /headers/*[3]')

	-- And the alter the To node.
	SET	@EmailHeaders.modify('replace value of (/headers/header/@value)[2] with sql:variable("@RecipientOverride")')
END

-- Give back the final resultset.
SELECT	
		eml.EmailID,
		@EmailHeaders AS EmailHeaders,
		eml.EmailTemplateFileName,
		eml.EmailBody,
		eml.EmailSignature,
		eml.EmailFooter,
		eml.CreationDate,
		eml.SentDate
FROM	eml.tblEmail eml
WHERE	eml.EmailID = @EmailID

--EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== eml.uspEmail_Get ======================================================================	*/
