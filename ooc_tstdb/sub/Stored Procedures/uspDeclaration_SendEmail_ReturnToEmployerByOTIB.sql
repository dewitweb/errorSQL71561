
CREATE PROCEDURE [sub].[uspDeclaration_SendEmail_ReturnToEmployerByOTIB]
@DeclarationID	int,
@Reason			varchar(MAX)
AS
/*	==========================================================================================
	Purpose:	Sends e-mails to employers which declarations have been returned.

	06-01-2020	Jaap van Assenbergh	OTIBSUB-1798	Banner per period or default
	21-05-2019	Sander van Houten	OTIBSUB-1100	Change e-mail text Return Employer.		
	07-05-2019	Jaap van Assenbergh	Initial version.		
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Creation_DateTime  datetime = GETDATE()
DECLARE @TemplateID			int = 24
DECLARE @EmailHeader		varchar(MAX),
		@EmailBody			varchar(MAX),
		@SubjectAddition	varchar(100) = '',
		@Recipients			varchar(MAX)

DECLARE @DeclarationDate105	varchar(20)
DECLARE @DeclarationNumber	varchar(6)

/*	Get SubsidySchemeName.	*/
DECLARE	@SubsidySchemeName	varchar(50),
		@LogDate			datetime = GETDATE(),
		@MailBanner			varchar(100),
		@InsertedUserID		int,
		@UserID				int,
		@Email				varchar(50),
		@Infix				varchar(15),
		@Surname			varchar(50),
		@SalutationName		varchar(65),
		@DeclarationDate	date

SELECT	@SubsidySchemeName = ssc.SubsidySchemeName
FROM	sub.tblDeclaration decl
INNER JOIN sub.tblSubsidyScheme ssc ON ssc.SubsidySchemeID = decl.SubsidySchemeID
WHERE	decl.DeclarationID = @DeclarationID

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
WHERE	TableName = 'sub.tblDeclaration'
AND		KeyID = CAST(@DeclarationID AS varchar(6))
AND		OldValue IS NULL								-- Inserted by userID

SELECT @Email = e.Email, @UserID = UserID
FROM
		(
			SELECT eem.Email, eem.UserID,
			ROW_NUMBER() OVER (PARTITION BY decl.Employernumber ORDER BY CASE WHEN ISNULL(eem.UserID, 0) = @InsertedUserID THEN 0 ELSE 1 END ASC) Rownr
			FROM sub.tblDeclaration decl
			INNER JOIN sub.viewEmployerEmail eem
				ON	eem.EmployerNumber = decl.EmployerNumber
			WHERE	decl.DeclarationID = @DeclarationID
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
SELECT	@DeclarationNumber = CAST(decl.DeclarationID AS varchar(6)),
		@DeclarationDate105 = CONVERT(varchar(15), decl.DeclarationDate , 105),
		@SubjectAddition = ' ' + @SubsidySchemeName + 
		CASE
			WHEN ISNULL(evcd.IsEVC500, 0) = 1 
			THEN '-500' 
			ELSE ''
		END  + ' declaratie ' + CAST(decl.DeclarationID AS varchar(6))
FROM	sub.tblDeclaration decl
INNER JOIN sub.viewEmployerEmail emp
	ON		emp.EmployerNumber = decl.EmployerNumber
LEFT JOIN evc.viewDeclaration evcd 
	ON evcd.DeclarationID = decl.DeclarationID
WHERE	decl.DeclarationID = @DeclarationID

SELECT @Reason = 
		CASE 
			WHEN @Reason <> ''	
			THEN
				'De reden hiervoor is: ' + @Reason + '<br>'
			ELSE
				''
		END

SET @Recipients = REPLACE(@Email, '&' , '&amp;')
SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', @Recipients)
SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', @SubjectAddition)

SET @EmailBody = REPLACE(@EmailBody, '<%SalutationName%>', @SalutationName)
SET @EmailBody = REPLACE(@EmailBody, '<%DeclarationNumber%>', @DeclarationNumber)
SET @EmailBody = REPLACE(@EmailBody, '<%Reason%>', @Reason)
SET @EmailBody = REPLACE(@EmailBody, '<%DeclarationDate%>', @DeclarationDate105)
SET @EmailBody = REPLACE(@EmailBody, '<%MailBanner%>', @MailBanner)

--INSERT INTO eml.tblEmail
--			(EmailHeaders,
--			EmailBody,
--			CreationDate,
--			SentDate)
--SELECT	'<headers>'
--		+ '<header key="subject" value="OTIB Online: Wijzigen ' + @SubsidySchemeName + CASE WHEN ISNULL(evcd.IsEVC500, 0) = 1 
--																							THEN '-500' 
--																							ELSE ''
--																					   END  + ' declaratie ' + CAST(decl.DeclarationID AS varchar(6)) + '" />'
--        + '<header key="to" value="' + REPLACE(@Email, '&', '&amp;') + '" />'
--		+ '</headers>'	AS EmailHeaders,
--		+ '<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>'+ @SalutationName +'<br>'
--		+ '<br>'
--		+ 'Op ' + CONVERT(varchar(15), decl.DeclarationDate , 105) + ' hebben wij uw declaratie ontvangen met declaratienummer ' + CAST(decl.DeclarationID AS varchar(6)) + '. Helaas kunnen wij deze declaratie op dit moment niet in behandeling nemen. <br>' + 
--		CASE WHEN @Reason <> ''	
--			THEN
--			'De reden hiervoor is: ' + @Reason + '<br>'
--		ELSE
--			''
--		END
--		+ '<br>
--		Wij verzoeken u vriendelijk de declaratie te wijzigen en hierna opnieuw in te dienen, zodat wij deze in behandeling kunnen nemen. Als u nog vragen heeft, kunt u contact opnemen met de OTIB Supportdesk op telefoonnummer 0800-885 58 85.<br>'
--		+ '<br><br>'
--		+ 'Met vriendelijke groet,<br>'
--		+ 'OTIB<br>'
--		+ '<a href="mailto:support@otib.nl">support@otib.nl</a><br>'
--		+ 'T 0800 885 58 85<br>'
--		+ '<img src="' + @MailBanner + '" width="450" style="border: none;" />'
--		+ '</p>'			AS EmailBody,
--		@LogDate		AS CreationDate,
--		NULL			AS SentDate
--FROM	sub.tblDeclaration decl
--INNER JOIN sub.viewEmployerEmail emp
--	ON		emp.EmployerNumber = decl.EmployerNumber
--LEFT JOIN evc.viewDeclaration evcd 
--	ON evcd.DeclarationID = decl.DeclarationID
--WHERE	decl.DeclarationID = @DeclarationID

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

/*	== sub.uspDeclaration_SendEmail_ReturnToEmployerByOTIB ===============================================	*/
