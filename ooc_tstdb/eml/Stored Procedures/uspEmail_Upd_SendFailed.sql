
CREATE PROCEDURE [eml].[uspEmail_Upd_SendFailed]
@EmailID	int,
@SendLog	varchar(MAX)
AS
/*	==========================================================================================
	Purpose:	Register failure in sending an e-mail.

	05-09-2019	Sander van Houten		AII-18		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Creation_DateTime  datetime = GETDATE()
DECLARE @TemplateID			int = 8
DECLARE @EmailHeader		varchar(MAX),
		@EmailBody			varchar(MAX),
		@SubjectAddition	varchar(100) = '',
		@Recipients			varchar(MAX)

DECLARE @RetryCount		int,
		@EmailHeaderXML	xml

-- Update eml.tblEmail.
UPDATE	eml.tblEmail
SET		RetryCount = RetryCount + 1,
		SendLog = @SendLog,
		@RetryCount = RetryCount + 1,
		@EmailHeaderXML = EmailHeaders
WHERE	EmailID = @EmailID

-- Send an e-mail to Ambition IT support.
IF	@RetryCount = (	SELECT	CAST(SettingValue AS int)
					FROM	eml.tblEmailSetting
					WHERE	SettingName = 'MaxRetries'
				  )
AND	CAST(@EmailHeaderXML AS varchar(MAX)) NOT LIKE '%support@ambitionit.nl%'

BEGIN

	SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
	SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

	SET @Recipients = 'support@ambitionit.nl'

	SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', ISNULL(@Recipients, ''))
	SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%EmailID%>', ISNULL(CAST(@EmailID AS varchar(18)),''))
	SET @EmailBody = REPLACE(@EmailBody, '<%RetryCount%>', CAST(@RetryCount AS varchar(10)))

--	INSERT INTO eml.tblEmail 
--		(
--			EmailHeaders, 
--			EmailBody
--		) 
--	SELECT
--			'<headers>'
--				+ '<header key="subject" value="Fout bij verzending e-mail vanuit ' + DB_NAME() + '" />'
--				+ '<header key="to" value="support@ambitionit.nl" />'
--				+ '</headers>',
--			'<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>Beste afdeling Support,' +
--				+ '<br><br>'
--				+ 'De verzending van de e-mail met ID ' + CAST(EmailID AS varchar(18)) + ' is ' + CAST(@RetryCount AS varchar(10)) + ' keer fout gelopen dat dit jullie aandacht nodig heeft.'
--				+ '</p>'
--	FROM	eml.tblEmail
--	WHERE	EmailID = @EmailID

	INSERT INTO eml.tblEmail
		(
			EmailHeaders,
			EmailBody,
			CreationDate
		)
	VALUES
		(
			@EmailHeader,
			@EmailBody,
			@Creation_DateTime
		)
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== eml.uspEmail_Upd_SendFailed ===========================================================	*/

