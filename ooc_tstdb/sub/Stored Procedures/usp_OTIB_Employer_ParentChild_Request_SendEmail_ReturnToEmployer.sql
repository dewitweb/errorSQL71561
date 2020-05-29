
CREATE PROCEDURE [sub].[usp_OTIB_Employer_ParentChild_Request_SendEmail_ReturnToEmployer]
@RequestID	int,
@Reason			varchar(MAX)
AS
/*	==========================================================================================
	Purpose:	Sends e-mails to employers which declarations have been returned.

	06-01-2020	Jaap van Assenbergh	OTIBSUB-1798	Banner per period or default
	27-09-2019	Sander van Houten	OTIBSUB-100		Initial version.		
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Creation_DateTime  datetime = GETDATE()
DECLARE @TemplateID			int = 23
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
		@CreationDate		date

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
WHERE	TableName = 'sub.tblEmployer_ParentChild_Request'
AND		KeyID = CAST(@RequestID AS varchar(18))
AND		OldValue IS NULL								-- Inserted by userID

SELECT @Email = e.Email, @UserID = UserID
FROM
		(
			SELECT	eem.Email, eem.UserID,
			ROW_NUMBER() OVER (PARTITION BY epcr.EmployernumberChild ORDER BY CASE WHEN ISNULL(eem.UserID, 0) = @InsertedUserID THEN 0 ELSE 1 END ASC) Rownr
			FROM	sub.tblEmployer_ParentChild_Request epcr
			INNER JOIN sub.viewEmployerEmail eem
			ON		eem.EmployerNumber = epcr.EmployerNumberChild
			WHERE	epcr.RequestID = @RequestID
		) e
WHERE Rownr = 1		-- Inserted user first else other users

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
SELECT	@CreationDate = Creation_DateTime
FROM	sub.tblEmployer_ParentChild_Request epcr
INNER JOIN sub.viewEmployerEmail emp
ON		emp.EmployerNumber = epcr.EmployerNumberChild
WHERE	epcr.RequestID = @RequestID

SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

SELECT @Reason = 
		CASE 
			WHEN @Reason <> ''	
			THEN
				'De reden hiervoor is: ' + @Reason + '<br>'
			ELSE
				''
		END

SET @Recipients = REPLACE(@Email, '&' , '&amp;')
SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', ISNULL(@Recipients, ''))
SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))

SET @EmailBody = REPLACE(@EmailBody, '<%SalutationName%>', ISNULL(@SalutationName, ''))
SET @EmailBody = REPLACE(@EmailBody, '<%Reason%>', ISNULL(@Reason, ''))
SET @EmailBody = REPLACE(@EmailBody, '<%CreationDate%>', ISNULL(CONVERT(varchar(10), @CreationDate, 105),''))
SET @EmailBody = REPLACE(@EmailBody, '<%MailBanner%>', ISNULL(@MailBanner, ''))

--INSERT INTO eml.tblEmail
--			(EmailHeaders,
--			EmailBody,
--			CreationDate,
--			SentDate)
--SELECT	'<headers>'
--		+ '<header key="subject" value="OTIB Online: Wijzigen concernrelatie" />'
--        + '<header key="to" value="' + REPLACE(@Email, '&', '&amp;') + '" />'
--		+ '</headers>'	AS EmailHeaders,
--		+ '<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>'+ @SalutationName +'<br>'
--		+ '<br>'
--		+ 'Op ' + CONVERT(varchar(15), epcr.Creation_DateTime , 105) + ' hebben wij uw aanvraag ontvangen . Helaas kunnen wij deze aanvraag op dit moment niet in behandeling nemen. <br>' + 
--		CASE WHEN @Reason <> ''	
--			THEN
--			'De reden hiervoor is: ' + @Reason + '<br>'
--		ELSE
--			''
--		END
--		+ '<br>
--		Wij verzoeken u vriendelijk de aanvraag te wijzigen en hierna opnieuw in te dienen, zodat wij deze in behandeling kunnen nemen. Als u nog vragen heeft, kunt u contact opnemen met de OTIB Supportdesk op telefoonnummer 0800-885 58 85.<br>'
--		+ '<br><br>'
--		+ 'Met vriendelijke groet,<br>'
--		+ 'OTIB<br>'
--		+ '<a href="mailto:support@otib.nl">support@otib.nl</a><br>'
--		+ 'T 0800 885 58 85<br>'
--		+ '<img src="' + @MailBanner + '" width="450" style="border: none;" />'
--		+ '</p>'			AS EmailBody,
--		@LogDate		AS CreationDate,
--		NULL			AS SentDate
--FROM	sub.tblEmployer_ParentChild_Request epcr
--INNER JOIN sub.viewEmployerEmail emp
--ON		emp.EmployerNumber = epcr.EmployerNumberChild
--WHERE	epcr.RequestID = @RequestID

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

/*	== sub.usp_OTIB_Employer_ParentChild_Request_SendEmail_ReturnToEmployer ==================	*/
