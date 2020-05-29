
CREATE PROCEDURE [auth].[uspUserValidation_SendMail]
@UserID int
AS
/*	==========================================================================================
	Purpose:	Send an e-mail to a user to validate his/her e-mail address

	06-01-2020	Jaap van Assenbergh	OTIBSUB-1798	Banner per period or default
	27-06-2019	Sander van Houten		OTIBSUB-1277	Use correct e-mailaddress.
	24-04-2019	Sander van Houten		OTIBSUB-1011	Use of an ampersand (&) in an e-mailaddress
											gives xml-parsing error.
	02-04-2019	Sander van Houten		OTIBSUB-874		E-mail design changes.
	19-11-2018	Maarten Keijsers		Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Creation_DateTime  datetime = GETDATE()
DECLARE @TemplateID int = 7
DECLARE @EmailHeader	varchar(MAX),
		@EmailBody		varchar(MAX),
		@SubjectAddition varchar(100) = ''

DECLARE	@RecipientOverride	varchar(100),
		@LinkURL			varchar(250),
		@Email				varchar(250),
		@MailBanner			varchar(100),
		@Recipients			varchar(MAX)
	
SELECT	@RecipientOverride = SettingValue
FROM	eml.tblEmailSetting
WHERE	SettingName = 'RecipientOverride'

SELECT	@Email =
				 CASE WHEN ISNULL(@RecipientOverride, '') <> '' 
						THEN @RecipientOverride 
						ELSE 
							CASE WHEN v.UserID IS NOT NULL AND v.EmailCheck = 0
								THEN u.Email 
								ELSE uec.Email_New 
							END
				END, 
		@LinkURL = CASE 
					WHEN DB_NAME() = 'OTIBDS' THEN CONCAT('https://otib-online.nl/email-bevestigen?userId=', @UserID, '&token=', ISNULL(v.EmailValidationToken, uec.EmailValidationToken))
					WHEN DB_NAME() = 'OTIBDSTest' THEN CONCAT('http://ui.subsidiesysteem.local/email-bevestigen?userId=', @UserID, '&token=', ISNULL(v.EmailValidationToken, uec.EmailValidationToken))
					WHEN DB_NAME() = 'OTIBDS_Acceptatie' THEN CONCAT('https://acceptatie.otib-online.nl/email-bevestigen?userId=', @UserID, '&token=', ISNULL(v.EmailValidationToken, uec.EmailValidationToken))
				   END
FROM	auth.tblUser u 
LEFT  JOIN auth.tblUserValidation v ON v.UserID = u.UserID
LEFT  JOIN auth.tblUser_Email_Change uec ON uec.UserID = u.UserID
WHERE	u.UserID = @UserID

-- Get MailBanner location.
SELECT	@MailBanner = COALESCE(apse.SettingValue, aps.SettingValue)
FROM	sub.tblApplicationSetting aps
LEFT JOIN sub.tblApplicationSetting_Extended apse 
	ON	apse.ApplicationSettingID = aps.ApplicationSettingID 
	AND	GETDATE() BETWEEN apse.StartDate AND apse.EndDate
WHERE	aps.SettingName = 'BaseURL'
AND		aps.SettingCode = 'AssetsMailBanner'

SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

SET @Recipients = REPLACE(@Email, '&' , '&amp;')
SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', ISNULL(@Recipients, ''))
SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))

SET @EmailBody = REPLACE(@EmailBody, '<%LinkURL%>', ISNULL(@LinkURL, ''))
SET @EmailBody = REPLACE(@EmailBody, '<%MailBanner%>', ISNULL(@MailBanner, ''))

--INSERT INTO eml.tblEmail
--			(EmailHeaders
--			,EmailBody
--			,CreationDate)
--SELECT	'<headers>'
--		+ '<header key="subject" value="OTIB Online: E-mailadres bevestiging" />'
--		+ '<header key="to" value="' + REPLACE(@Email, '&', '&amp;') + '" />'
--		+ '</headers>'	AS EmailHeaders,
--		'<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>Bevestig uw e-mailadres door op onderstaande link te klikken.<br>'+
--		'<a href="'+@LinkURL+'">'+@LinkURL+'</a>' +
--		'<br>' +
--		'Wij hopen u hiermee voldoende te hebben geïnformeerd.<br>' +
--		'<br><br>' +
--		'Met vriendelijke groet,<br>' +
--		'OTIB<br>' +
--		'<a href="mailto:support@otib.nl">support@otib.nl</a><br>' +
--		'T 0800 885 58 85<br>' +
--		'<img src="' + @MailBanner + '" width="450" style="border: none;" />' +
--		'</p>'			AS EmailBody,
--		GETDATE()		AS CreationDate
--WHERE	@LinkURL IS NOT NULL 
--  AND	@Email IS NOT NULL

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

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== auth.uspUserValidation_SendMail =======================================================	*/
