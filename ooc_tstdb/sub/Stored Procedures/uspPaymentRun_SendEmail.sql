
CREATE PROCEDURE [sub].[uspPaymentRun_SendEmail]
@PaymentRunID	int
AS
/*	==========================================================================================
	Purpose:	Sends e-mails to employers which declarations have been processed.

	Note:		

	06-01-2020	Jaap van Assenbergh	OTIBSUB-1798	Banner per period or default
	08-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus -> PartitionStatus.
	24-06-2019	Sander van Houten	OTIBSUB-1253	Changed the e-mail subject text.
	24-04-2019	Sander van Houten	OTIBSUB-1011	Use of an ampersand (&) in an e-mailaddress
										gives xml-parsing error.
	16-04-2019	Sander van Houten	OTIBSUB-971		Split up-paymentrun, e-mail sending and 
										export to Exact.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Creation_DateTime  datetime = GETDATE()
DECLARE @TemplateID			int = 28
DECLARE @EmailHeader		varchar(MAX),
		@EmailBody			varchar(MAX),
		@SubjectAddition	varchar(100) = '',
		@Recipients			varchar(MAX)

/*	Get SubsidySchemeName.	*/
DECLARE	@SubsidySchemeName	varchar(50),
		@LogDate			datetime = GETDATE(),
		@MailBanner			varchar(100)

DECLARE	@Email					varchar(50),
		@IBAN					varchar(34),
		@DeclarationNumber		varchar(6),
		@DeclarationDescription	varchar(133),
		@LinkURL				varchar(250)

SELECT	@SubsidySchemeName = ssc.SubsidySchemeName
FROM	sub.tblPaymentRun par
INNER JOIN sub.tblSubsidyScheme ssc ON ssc.SubsidySchemeID = par.SubsidySchemeID
WHERE	par.PaymentRunID = @PaymentRunID

-- Get MailBanner location.
SELECT	@MailBanner = COALESCE(apse.SettingValue, aps.SettingValue)
FROM	sub.tblApplicationSetting aps
LEFT JOIN sub.tblApplicationSetting_Extended apse 
	ON	apse.ApplicationSettingID = aps.ApplicationSettingID 
	AND	GETDATE() BETWEEN apse.StartDate AND apse.EndDate
WHERE	aps.SettingName = 'BaseURL'
AND		aps.SettingCode = 'AssetsMailBanner'


/* Give feedback to declarant through an e-mail.	*/
DECLARE cur_Email CURSOR 
	LOCAL    
	STATIC
	READ_ONLY
	FORWARD_ONLY
	FOR 
	SELECT	emp.Email,
			' ' + @SubsidySchemeName + 
			CASE
				WHEN ISNULL(evcd.IsEVC500, 0) = 1 
				THEN '-500' 
				ELSE ''
			END,
			CAST(d.DeclarationID AS varchar(10)),
			CASE d.SubsidySchemeID
				WHEN 1 THEN osrd.CourseName 
				WHEN 3 THEN evcd.Employee
				WHEN 4 THEN stpd.Employee
				WHEN 5 THEN evcwvd.ParticipantName
				ELSE ''
			END, 
			CASE 
				WHEN DB_NAME() = 'OTIBDS' THEN 'De specificatie is terug te vinden in het <a href="https://otib-online.nl">declaratiesysteem. </a>'
				WHEN DB_NAME() = 'OTIBDSTest' THEN 'De specificatie is terug te vinden in het <a href="http://ui.subsidiesysteem.local">declaratiesysteem. </a>'
				WHEN DB_NAME() = 'OTIBDS_Acceptatie' THEN 'De specificatie is terug te vinden in het <a href="https://acceptatie.otib-online.nl">declaratiesysteem. </a>'
			END,
			CASE ISNULL(pad.IBAN, '') WHEN '' THEN 'ONBEKEND' ELSE pad.IBAN END
	FROM	sub.tblPaymentRun_Declaration pad
	INNER JOIN sub.tblDeclaration d
			ON		d.DeclarationID = pad.DeclarationID
	INNER JOIN	sub.viewEmployerEmail emp
			ON	emp.EmployerNumber = d.EmployerNumber
	INNER JOIN	sub.tblDeclaration_Partition dep
			ON	dep.PartitionID = pad.PartitionID
	LEFT JOIN	evc.viewDeclaration evcd 
			ON	evcd.DeclarationID = d.DeclarationID
	LEFT JOIN	evcwv.viewDeclaration evcwvd 
			ON	evcwvd.DeclarationID = d.DeclarationID
	LEFT JOIN	osr.viewDeclaration osrd
			ON	osrd.DeclarationID = d.DeclarationID
	LEFT JOIN	stip.viewDeclaration stpd 
			ON	stpd.DeclarationID = d.DeclarationID
	WHERE	pad.PaymentRunID = @PaymentRunID
	AND		COALESCE(pad.ReversalPaymentID, 0) = 0
	AND		dep.PartitionStatus <> '0017' -- Rejections will not trigger an e-mail.
OPEN cur_Email

FETCH FROM cur_Email INTO 
	@Email, 
	@SubjectAddition, 
	@DeclarationNumber, 
	@DeclarationDescription,
	@LinkURL,
	@IBAN

WHILE @@FETCH_STATUS = 0  
BEGIN
	SET @EmailHeader = ''
	SET @EmailBody = ''
	SET @Recipients = ''

	SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
	SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

	SET @Recipients = REPLACE(@Email, '&' , '&amp;')
--	SET @EmailHeader = REPLACE(@EmailHeader, '<%SubsidySchemeName%>', @SubsidySchemeName)
	SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', ISNULL(@Recipients, ''))
	SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))

	SET @EmailBody = REPLACE(@EmailBody, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%IBAN%>', ISNULL(@IBAN, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%DeclarationNumber%>', ISNULL(@DeclarationNumber, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%DeclarationDescription%>', ISNULL(@DeclarationDescription, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%LinkURL%>', ISNULL(@LinkURL, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%MailBanner%>', ISNULL(@MailBanner, ''))

	------ For regular declarations.
	--INSERT INTO eml.tblEmail
	--			(EmailHeaders,
	--			EmailBody,
	--			CreationDate,
	--			SentDate)
	--SELECT	'<headers>'
	--		+ '<header key="subject" value="OTIB Online: ' + @SubsidySchemeName + '-uitbetaling" />'
	--        + '<header key="to" value="' + REPLACE(emp.Email, '&', '&amp;') + '" />'
	--		+ '</headers>'  AS EmailHeaders,
	--		'<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>Geachte mevrouw, heer,<br>' 
	--        + '<br>' 
	--        + 'De volgende ' 
	--		+ @SubsidySchemeName + CASE WHEN ISNULL(evcd.IsEVC500, 0) = 1 OR ISNULL(evcwvd.IsEVC500, 0) = 1 
	--									THEN '-500' 
	--									ELSE ''
	--							   END 
	--		+ ' declaratie is verwerkt in ons systeem: <br>' 
	--        + CAST(d.DeclarationID AS varchar(10)) + ' ' 
	--        + CASE d.SubsidySchemeID
	--            WHEN 1 THEN osrd.CourseName 
	--            WHEN 3 THEN evcd.Employee
	--            WHEN 4 THEN stpd.Employee
	--            WHEN 5 THEN evcwvd.ParticipantName
	--            ELSE ''
	--          END 
	--        + '<br><br>' 
	--        + CASE 
	--			WHEN DB_NAME() = 'OTIBDS' THEN 'De specificatie is terug te vinden in het <a href="https://otib-online.nl">declaratiesysteem. </a>'
	--			WHEN DB_NAME() = 'OTIBDSTest' THEN 'De specificatie is terug te vinden in het <a href="http://ui.subsidiesysteem.local">declaratiesysteem. </a>'
	--			WHEN DB_NAME() = 'OTIBDS_Acceptatie' THEN 'De specificatie is terug te vinden in het <a href="https://acceptatie.otib-online.nl">declaratiesysteem. </a>'
	--		  END
	--        + 'Op de specificatie staat de hoogte van de tegemoetkoming.<br>' 
	--        + '<br>' 
	--        + 'De vergoeding zal op uw bankrekening ' + CASE ISNULL(pad.IBAN, '') WHEN '' THEN 'ONBEKEND' ELSE pad.IBAN END + ' worden bijgeschreven.<br>' 
	--        + '<br><br>' 
	--        + 'Met vriendelijke groet,<br>' 
	--        + 'OTIB<br>' 
	--        + '<a href="mailto:support@otib.nl">support@otib.nl</a><br>' 
	--        + 'T 0800 885 58 85<br>' 
	--        + '<img src="' + @MailBanner + '" width="450" style="border: none;" />' 
	--        + '</p>'		AS EmailBody,
	--		@LogDate		AS CreationDate,
	--		NULL			AS SentDate
	--FROM	sub.tblPaymentRun_Declaration pad
	--INNER JOIN sub.tblDeclaration d
	--		ON		d.DeclarationID = pad.DeclarationID
	--INNER JOIN	sub.viewEmployerEmail emp
	--		ON	emp.EmployerNumber = d.EmployerNumber
	--INNER JOIN	sub.tblDeclaration_Partition dep
	--		ON	dep.PartitionID = pad.PartitionID
	--LEFT JOIN	evc.viewDeclaration evcd 
	--		ON	evcd.DeclarationID = d.DeclarationID
	--LEFT JOIN	evcwv.viewDeclaration evcwvd 
	--		ON	evcwvd.DeclarationID = d.DeclarationID
	--LEFT JOIN	osr.viewDeclaration osrd
	--		ON	osrd.DeclarationID = d.DeclarationID
	--LEFT JOIN	stip.viewDeclaration stpd 
	--		ON	stpd.DeclarationID = d.DeclarationID
	--WHERE	pad.PaymentRunID = @PaymentRunID
	--AND		COALESCE(pad.ReversalPaymentID, 0) = 0
	--AND		dep.PartitionStatus <> '0017'	-- Rejections will not trigger an e-mail.

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

	FETCH NEXT FROM cur_Email INTO 
		@Email, 
		@SubjectAddition, 
		@DeclarationNumber, 
		@DeclarationDescription,
		@LinkURL,
		@IBAN
END

CLOSE cur_Email
DEALLOCATE cur_Email

-- For reversals.
SET @TemplateID = 29

DECLARE cur_Email CURSOR 
	LOCAL    
	STATIC
	READ_ONLY
	FORWARD_ONLY
	FOR 
	SELECT	emp.Email,
			' ' + @SubsidySchemeName + 
			CASE
				WHEN ISNULL(evcd.IsEVC500, 0) = 1 
				THEN '-500' 
				ELSE ''
			END,
			CAST(d.DeclarationID AS varchar(10)),
			CASE d.SubsidySchemeID
				WHEN 1 THEN osrd.CourseName 
				WHEN 3 THEN evcd.Employee
				WHEN 4 THEN stpd.Employee
				WHEN 5 THEN evcwvd.ParticipantName
				ELSE ''
			END, 
			CASE 
				WHEN DB_NAME() = 'OTIBDS' THEN 'De specificatie is terug te vinden in het <a href="https://otib-online.nl">declaratiesysteem. </a>'
				WHEN DB_NAME() = 'OTIBDSTest' THEN 'De specificatie is terug te vinden in het <a href="http://ui.subsidiesysteem.local">declaratiesysteem. </a>'
				WHEN DB_NAME() = 'OTIBDS_Acceptatie' THEN 'De specificatie is terug te vinden in het <a href="https://acceptatie.otib-online.nl">declaratiesysteem. </a>'
			END,
			CASE ISNULL(pad.IBAN, '') WHEN '' THEN 'ONBEKEND' ELSE pad.IBAN END
	FROM	sub.tblPaymentRun_Declaration pad
	INNER JOIN sub.tblDeclaration d
	ON		d.DeclarationID = pad.DeclarationID
	INNER JOIN sub.viewEmployerEmail emp
	ON		emp.EmployerNumber = d.EmployerNumber
	LEFT JOIN evc.viewDeclaration evcd 
	ON      evcd.DeclarationID = d.DeclarationID
	LEFT JOIN evcwv.viewDeclaration evcwvd 
	ON      evcwvd.DeclarationID = d.DeclarationID
	LEFT JOIN osr.viewDeclaration osrd
	ON      osrd.DeclarationID = d.DeclarationID
	LEFT JOIN stip.viewDeclaration stpd 
	ON      stpd.DeclarationID = d.DeclarationID
	WHERE	pad.PaymentRunID = @PaymentRunID
	AND		COALESCE(pad.ReversalPaymentID, 0) <> 0
OPEN cur_Email

FETCH FROM cur_Email INTO 
	@Email, 
	@SubjectAddition, 
	@DeclarationNumber, 
	@DeclarationDescription,
	@LinkURL,
	@IBAN

WHILE @@FETCH_STATUS = 0  
BEGIN
	SET @EmailHeader = ''
	SET @EmailBody = ''
	SET @Recipients = ''

	SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
	SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

	SET @Recipients = REPLACE(@Email, '&' , '&amp;')
--	SET @EmailHeader = REPLACE(@EmailHeader, '<%SubsidySchemeName%>', @SubsidySchemeName)
	SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', ISNULL(@Recipients, ''))
	SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))

	SET @EmailBody = REPLACE(@EmailBody, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%IBAN%>', ISNULL(@IBAN, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%DeclarationNumber%>', ISNULL(@DeclarationNumber, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%DeclarationDescription%>', ISNULL(@DeclarationDescription, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%LinkURL%>', ISNULL(@LinkURL, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%MailBanner%>', ISNULL(@MailBanner, ''))

	--INSERT INTO eml.tblEmail
	--			(EmailHeaders,
	--			EmailBody,
	--			CreationDate,
	--			SentDate)
	--SELECT	'<headers>'
	--		+ '<header key="subject" value="OTIB Online: ' + @SubsidySchemeName + '-uitbetaling" />'
	--        + '<header key="to" value="' + REPLACE(emp.Email, '&', '&amp;') + '" />'
	--		+ '</headers>'  AS EmailHeaders,
	--		'<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>Geachte mevrouw, heer,<br>' 
	--        + '<br>' 
	--        + 'De volgende ' 
	--		+ @SubsidySchemeName + CASE WHEN ISNULL(evcd.IsEVC500, 0) = 1 OR ISNULL(evcwvd.IsEVC500, 0) = 1 
	--									THEN '-500' 
	--									ELSE ''
	--							   END 
	--		+ ' declaratie is verwerkt in ons systeem: <br>' 
	--        + CAST(d.DeclarationID AS varchar(10)) + ' ' 
	--        + CASE d.SubsidySchemeID
	--            WHEN 1 THEN osrd.CourseName 
	--            WHEN 3 THEN evcd.Employee
	--            WHEN 4 THEN stpd.Employee
	--            WHEN 5 THEN evcwvd.ParticipantName
	--            ELSE ''
	--          END 
	--        + '<br><br>' 
	--        + CASE 
	--			WHEN DB_NAME() = 'OTIBDS' THEN 'De specificatie is terug te vinden in het <a href="https://otib-online.nl">declaratiesysteem. </a>'
	--			WHEN DB_NAME() = 'OTIBDSTest' THEN 'De specificatie is terug te vinden in het <a href="http://ui.subsidiesysteem.local">declaratiesysteem. </a>'
	--			WHEN DB_NAME() = 'OTIBDS_Acceptatie' THEN 'De specificatie is terug te vinden in het <a href="https://acceptatie.otib-online.nl">declaratiesysteem. </a>'
	--		  END
	--		+ 'Op de specificatie vindt u de hoogte van de tegenboeking.<br>'
	--        + '<br>' 
	--        + 'De vergoeding zal op uw bankrekening ' + CASE ISNULL(pad.IBAN, '') WHEN '' THEN 'ONBEKEND' ELSE pad.IBAN END + ' worden bijgeschreven.<br>' 
	--        + '<br><br>' 
	--        + 'Met vriendelijke groet,<br>' 
	--        + 'OTIB<br>' 
	--        + '<a href="mailto:support@otib.nl">support@otib.nl</a><br>' 
	--        + 'T 0800 885 58 85<br>' 
	--        + '<img src="' + @MailBanner + '" width="450" style="border: none;" />' 
	--        + '</p>'		AS EmailBody,
	--		@LogDate		AS CreationDate,
	--		NULL			AS SentDate
	--FROM	sub.tblPaymentRun_Declaration pad
	--INNER JOIN sub.tblDeclaration d
	--ON		d.DeclarationID = pad.DeclarationID
	--INNER JOIN sub.viewEmployerEmail emp
	--ON		emp.EmployerNumber = d.EmployerNumber
	--LEFT JOIN evc.viewDeclaration evcd 
	--ON      evcd.DeclarationID = d.DeclarationID
	--LEFT JOIN evcwv.viewDeclaration evcwvd 
	--ON      evcwvd.DeclarationID = d.DeclarationID
	--LEFT JOIN osr.viewDeclaration osrd
	--ON      osrd.DeclarationID = d.DeclarationID
	--LEFT JOIN stip.viewDeclaration stpd 
	--ON      stpd.DeclarationID = d.DeclarationID
	--WHERE	pad.PaymentRunID = @PaymentRunID
	--AND		COALESCE(pad.ReversalPaymentID, 0) <> 0

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

	FETCH NEXT FROM cur_Email INTO 
		@Email, 
		@SubjectAddition, 
		@DeclarationNumber, 
		@DeclarationDescription,
		@LinkURL,
		@IBAN
END

CLOSE cur_Email
DEALLOCATE cur_Email

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspPaymentRun_SendEmail ===========================================================	*/
