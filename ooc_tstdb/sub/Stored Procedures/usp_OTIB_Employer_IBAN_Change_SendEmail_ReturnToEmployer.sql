
CREATE PROCEDURE [sub].[usp_OTIB_Employer_IBAN_Change_SendEmail_ReturnToEmployer]
@IBANChangeID	int,
@Reason			varchar(MAX)
AS
/*	==========================================================================================
	Purpose:	Sends e-mails to employers which declarations have been returned.

	09-01-2020	Sander van Houten	OTIBSUB-1821	Altered text in second paragraph.		
	18-11-2019	Sander van Houten	OTIBSUB-1718	Initial version.		
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Creation_DateTime  datetime = GETDATE()
DECLARE @TemplateID			int = 18
DECLARE @EmailHeader		varchar(MAX),
		@EmailBody			varchar(MAX),
		@SubjectAddition	varchar(100) = '',
		@Recipients			varchar(MAX)

-- Declare variables.
DECLARE	@LogDate			datetime = GETDATE(),
		@MailBanner			varchar(100),
		@InsertedUserID		int,
		@UserID				int,
		@Email				varchar(50),
		@Infix				varchar(15),
		@Surname			varchar(50),
		@SalutationName		varchar(65),
		@IBANDate105		varchar(20)
---- Get MailBanner location.
SELECT	@MailBanner = COALESCE(apse.SettingValue, aps.SettingValue)
FROM	sub.tblApplicationSetting aps
LEFT JOIN sub.tblApplicationSetting_Extended apse 
	ON	apse.ApplicationSettingID = aps.ApplicationSettingID 
	AND	GETDATE() BETWEEN apse.StartDate AND apse.EndDate
WHERE	aps.SettingName = 'BaseURL'
AND		aps.SettingCode = 'AssetsMailBanner'

SELECT	@InsertedUserID = UserID
FROM	his.tblHistory
WHERE	TableName = 'sub.tblEmployer_IBAN_Change'
AND		KeyID = CAST(@IBANChangeID AS varchar(18))
AND		OldValue IS NULL    						-- Inserted by userID

SELECT @Email = e.Email, @UserID = UserID
FROM
		(
			SELECT	eem.Email, 
                    eem.UserID
			FROM	sub.tblEmployer_IBAN_Change eic
			INNER JOIN sub.viewEmployerEmail eem
			ON		eem.EmployerNumber = eic.EmployerNumber
			WHERE	eic.IBANChangeID = @IBANChangeID
		) e

SELECT	@Infix = Infix, @Surname = Surname 
FROM	auth.tblUser
WHERE	UserID = @UserID
AND		COALESCE(Initials, FirstName, '') <> ''		-- Or initials or firstname is used bij SUrname is family name. Else companyname that not will be used in salutation

IF LTRIM(ISNULL(@Infix, '')) <> ''
BEGIN
	SET @Infix = UPPER(LEFT(@Infix, 1)) + LOWER(SUBSTRING(@Infix, 2, LEN(@Infix)))
END
SET @SalutationName = LTRIM(ISNULL(@Infix,'') + ' ' + ISNULL(@Surname, ''))
SET @SalutationName = RTRIM('Geachte mevrouw, heer '+ @SalutationName) + ','

/* Give feedback to declarant through e-mail.	*/

SELECT @Reason = 
		CASE 
			WHEN @Reason <> ''	
			THEN
				'Wij kunnen deze aanvraag nog niet in behandeling nemen. De reden hiervoor is: ' + @Reason + '<br>'
			ELSE
				''
		END

SELECT	@IBANDate105 = CONVERT(varchar(15), eic.Creation_DateTime , 105)
FROM	sub.tblEmployer_IBAN_Change eic
INNER JOIN sub.viewEmployerEmail emp
ON		emp.EmployerNumber = eic.EmployerNumber
WHERE	eic.IBANChangeID = @IBANChangeID


SET @Recipients = REPLACE(@Email, '&' , '&amp;')
SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', ISNULL(@Recipients, ''))
SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))

SET @EmailBody = REPLACE(@EmailBody, '<%SalutationName%>', ISNULL(@SalutationName, ''))
SET @EmailBody = REPLACE(@EmailBody, '<%IBANDate%>', ISNULL(@IBANDate105, ''))
SET @EmailBody = REPLACE(@EmailBody, '<%Reason%>', ISNULL(@Reason, ''))
SET @EmailBody = REPLACE(@EmailBody, '<%MailBanner%>', ISNULL(@MailBanner, ''))

--INSERT INTO eml.tblEmail
--			(EmailHeaders,
--			EmailBody,
--			CreationDate,
--			SentDate)
--SELECT	'<headers>'
--		+ '<header key="subject" value="OTIB Online: Aanvraag IBAN wijziging" />'
--        + '<header key="to" value="' + REPLACE(@Email, '&', '&amp;') + '" />'
--		+ '</headers>'	AS EmailHeaders,
--		+ '<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>'+ @SalutationName +'<br>'
--		+ '<br>'
--        + 'Geachte ' + ','
--		+ 'We hebben uw aanvraag voor het wijzigen van uw IBAN-nummer, ingediend op ' + CONVERT(varchar(15), eic.Creation_DateTime , 105) + ' ontvangen.<br>' + 
--		CASE WHEN @Reason <> ''	
--			THEN
--			'Wij kunnen deze aanvraag nog niet in behandeling nemen. De reden hiervoor is: ' + @Reason + '<br>'
--		ELSE
--			''
--		END
--		+ '<br>'
--		+ 'Wij verzoeken u vriendelijk uw aanvraag te wijzigen en opnieuw in te dienen, zodat wij deze in behandeling kunnen nemen. Voor het wijzigen van de aanvraag gaat u naar Instellingen, Bedrijfsgegevens, in OTIB Online.<br>'
--        + 'Als u nog vragen heeft, kunt u contact opnemen met de OTIB Supportdesk op telefoonnummer 0800-885 58 85.<br>'
--		+ '<br><br>'
--		+ 'Met vriendelijke groet,<br>'
--		+ 'OTIB<br>'
--		+ '<a href="mailto:support@otib.nl">support@otib.nl</a><br>'
--		+ 'T 0800 885 58 85<br>'
--		+ '<img src="' + @MailBanner + '" width="450" style="border: none;" />'
--		+ '</p>'		AS EmailBody,
--		@LogDate		AS CreationDate,
--		NULL			AS SentDate
--FROM	sub.tblEmployer_IBAN_Change eic
--INNER JOIN sub.viewEmployerEmail emp
--ON		emp.EmployerNumber = eic.EmployerNumber
--WHERE	eic.IBANChangeID = @IBANChangeID

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

/*	== sub.usp_OTIB_Employer_IBAN_Change_SendEmail_ReturnToEmployer ==========================	*/
