

CREATE PROCEDURE [stip].[uspProcessReferenceDate]
AS
/*	==========================================================================================
	Purpose:	Execute an action triggered bij reference date of a partition.

	Notes:		E-mailtexts come from S:\Klanten\OTIB\Subsidiesysteem\Teksten\
					20190802 FM OTIB DS STIP teksten e-mails.docx.

	06-01-2020	Jaap van Assenbergh	OTIBSUB-1798	Banner per period or default
	20-11-2019	Jaap van Assenbergh	Changes after testing. eml.SentDate <= @LogDate
	08-11-2019	Sander van Houten	OTIBSUB-1539	DeclarationStatus to '0034' or '0035'.
	09-09-2019	Sander van Houten	OTIBSUB-1544	New status 0029 Overdue (Vervallen).
	07-08-2019	Sander van Houten	OTIBSUB-1327	Changed URL template.
	06-08-2019	Sander van Houten	OTIBSUB-1327	Added update of declarationstatus
										and partitionstatus to 0026. 
	02-08-2019	Sander van Houten	OTIBSUB-1327	Added correct text for first and second e-mail.
	31-07-2019	Sander van Houten	OTIBSUB-1327	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Creation_DateTime  datetime = GETDATE()
DECLARE @TemplateID			int
DECLARE @EmailHeader		varchar(MAX),
		@EmailBody			varchar(MAX),
		@SubjectAddition	varchar(100) = '',
		@Recipients			varchar(MAX)

DECLARE @LogDate			datetime = GETDATE(),
		@MailBanner			varchar(100),
		@LinkURL			varchar(250),
		@DeclarationID		int,
		@PartitionID		int,
		@Email				varchar(50),
		@EmailID			int,
		@EmailSentDate		datetime,
		@EmployerNumber		varchar(6),
		@RC					int,
		@DeclarationStatus	varchar(24) = '0034',
		@StatusReason		varchar(MAX) = '',
		@PartitionStatus	varchar(4) = '0026',
		@CurrentUserID		int = 1
		
/* Give feedback to declarant through e-mail.	*/

-- Get MailBanner location.
SELECT	@MailBanner = COALESCE(apse.SettingValue, aps.SettingValue)
FROM	sub.tblApplicationSetting aps
LEFT JOIN sub.tblApplicationSetting_Extended apse 
	ON	apse.ApplicationSettingID = aps.ApplicationSettingID 
	AND	GETDATE() BETWEEN apse.StartDate AND apse.EndDate
WHERE	aps.SettingName = 'BaseURL'
AND		aps.SettingCode = 'AssetsMailBanner'

-- Insert e-mail 1 for sending.
-- Op een peildatum ontvangt de werkgever een e-mail van DS waarin hem gevraagd wordt 
-- de status van het STIP-subsidieaanvraag aan te geven.
DECLARE cur_Email1 CURSOR FOR 
	SELECT	d.DeclarationID,
			dep.PartitionID,
			eme.Email,
			d.EmployerNumber
	FROM	sub.tblDeclaration d
	INNER JOIN sub.tblDeclaration_Partition dep
	ON		dep.DeclarationID = d.DeclarationID
	INNER JOIN sub.viewEmployerEmail eme
	ON		eme.EmployerNumber = d.EmployerNumber
	LEFT JOIN stip.tblEmail_Partition epa
	ON		epa.PartitionID = dep.PartitionID
	AND		epa.LetterType = 1
	WHERE	d.SubsidySchemeID = 4
	AND		dep.PartitionStatus = '0037'
	AND		dep.PaymentDate <= @LogDate
	AND		epa.EmailID IS NULL
		
OPEN cur_Email1
FETCH FROM cur_Email1 INTO @DeclarationID, @PartitionID, @Email, @EmployerNumber

SET @TemplateID = 11

WHILE @@FETCH_STATUS = 0  
BEGIN
	SET	@LinkURL = CASE 
						WHEN DB_NAME() = 'OTIBDS' THEN CONCAT('https://otib-online.nl/status-overeenkomst/', @DeclarationID, '?employerNumber=', @EmployerNumber)
						WHEN DB_NAME() = 'OTIBDSTest' THEN CONCAT('http://ui.subsidiesysteem.local/status-overeenkomst/', @DeclarationID, '?employerNumber=', @EmployerNumber)
						WHEN DB_NAME() = 'OTIBDS_Acceptatie' THEN CONCAT('https://acceptatie.otib-online.nl/status-overeenkomst/', @DeclarationID, '?employerNumber=', @EmployerNumber)
				   END

	SET @Recipients = REPLACE(@Email, '&' , '&amp;')

	SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
	SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

	SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', ISNULL(@Recipients, ''))
	SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))

	SET @EmailBody = REPLACE(@EmailBody, '<%LinkURL%>', ISNULL(@LinkURL, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%MailBanner%>', ISNULL(@MailBanner, ''))

	---- Insert record into eml.tblEmail.
	--INSERT INTO eml.tblEmail
	--	(
	--		EmailHeaders,
	--		EmailBody,
	--		CreationDate,
	--		SentDate
	--	)
	--VALUES
	--	(	'<headers>'
	--		+ '<header key="subject" value="Stimuleringsregeling Praktijkbegeleiding (STIP); status van de opleiding" />'
	--		+ '<header key="to" value="' + REPLACE(@Email, '&', '&amp;') + '" />'
	--		+ '</headers>',
	--		'<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>' + 
	--		'Geachte mevrouw, heer,<br>' +
	--		'<br>' +
	--		'Volgens onze gegevens heeft u op basis van de Stimuleringsregeling Praktijkbegeleiding (STIP) - ' +
	--		'de bijdrage in de kosten van de begeleiding van leerling-werknemers door een praktijkopleider - recht op een vergoeding.<br>' +
	--		'<br>' +
	--		'Om te kunnen beoordelen of u ook daadwerkelijk voor deze vergoeding in aanmerking komt, vragen wij u <a href="' + @LinkURL + 
	--		'">hier</a> aan te geven of uw werknemer:<br>' +
	--		'<br>' +
	--		'a.	Nog bezig is met de opleiding.<br>' +
	--		'b.	Is geslaagd. Dan ontvangen wij graag binnen een half jaar na diplomadatum een kopie van het diploma.<br>' +
	--		'c.	Is gestopt met de opleiding.<br>' +
	--		'd.	Uit dienst is.<br>' +
	--		'<br>' +
	--		'Graag ontvangen wij deze informatie binnen drie weken na datum van dit bericht.' +
	--		'Als wij na drie weken deze informatie niet hebben ontvangen, vervalt het recht op betaling van de tegemoetkoming.<br>' +
	--		'<br>' +
	--		'Voor nadere informatie over de STIP kunt u <a href="www.otib.nl">www.otib.nl</a> of <a href="www.otib-online.nl">www.otib-online.nl</a> raadplegen.<br>' +
	--		'<br><br>' +			
	--		'Met vriendelijke groet,<br>' +
	--		'OTIB<br>' +
	--		'<a href="mailto:support@otib.nl">support@otib.nl</a><br>' +
	--		'T 0800 885 58 85<br>' +
	--		'<img src="' + @MailBanner + '" width="450" style="border: none;" />' +
	--		'</p>',
	--		@LogDate,
	--		'20991231'
	--	)

		INSERT INTO eml.tblEmail
			(
				EmailHeaders,
				EmailBody,
				CreationDate,
				SentDate
			)
		VALUES
			(
				@EmailHeader,
				@EmailBody,
				@Creation_DateTime,
				'20991231'
			)

	-- Retrieve added ID
	SET	@EmailID = SCOPE_IDENTITY()

	-- Insert record into stip.tblEmail_Partition.
	INSERT INTO stip.tblEmail_Partition
		(
			EmailID,
			PartitionID,
			LetterType
		)
	VALUES
		(
			@EmailID,
			@PartitionID,
			1
		)

	-- Update the declaration- and partitionstatus.
	EXECUTE @RC = sub.uspDeclaration_Upd_DeclarationStatus 
		@DeclarationID,
		@DeclarationStatus,
		@StatusReason,
		@CurrentUserID

	EXECUTE @RC = sub.uspDeclaration_Partition_Upd_PartitionStatus 
		@PartitionID,
		@PartitionStatus,
		@CurrentUserID

	FETCH NEXT FROM cur_Email1 INTO @DeclarationID, @PartitionID, @Email, @EmployerNumber
END

CLOSE cur_Email1
DEALLOCATE cur_Email1

-- Insert e-mail 2 for sending.
-- Een tweede e-mail wordt na twee weken verstuurd (indien geen reactie op eerste e-mail).
DECLARE cur_Email2 CURSOR FOR 
	SELECT	d.DeclarationID,
			dep.PartitionID,
			eme.Email,
			eml.SentDate,
			d.EmployerNumber
	FROM	stip.tblEmail_Partition epa1
	INNER JOIN sub.tblDeclaration_Partition dep
	ON		dep.PartitionID = epa1.PartitionID
	INNER JOIN sub.tblDeclaration d
	ON		d.DeclarationID = dep.DeclarationID
	INNER JOIN sub.viewEmployerEmail eme
	ON		eme.EmployerNumber = d.EmployerNumber
	INNER JOIN eml.tblEmail eml
	ON		eml.EmailID = epa1.EmailID
	LEFT JOIN stip.tblEmail_Partition epa2
	ON		epa2.PartitionID = dep.PartitionID
	AND		epa2.LetterType = 2
	WHERE	dep.PartitionStatus = @PartitionStatus
	AND		epa1.LetterType = 1
	AND		epa1.ReplyDate IS NULL
	AND		CAST(DATEADD(WW, 2, eml.SentDate) AS date) <= CAST(@LogDate AS date)
	AND		dep.PartitionStatus = '0026'
	AND		epa2.EmailID IS NULL

OPEN cur_Email2
FETCH FROM cur_Email2 INTO @DeclarationID, @PartitionID, @Email, @EmailSentDate, @EmployerNumber

SET @TemplateID = 12

WHILE @@FETCH_STATUS = 0  
BEGIN
	SET	@LinkURL = CASE 
						WHEN DB_NAME() = 'OTIBDS' THEN CONCAT('https://otib-online.nl/status-overeenkomst/', @DeclarationID, '?employerNumber=', @EmployerNumber)
						WHEN DB_NAME() = 'OTIBDSTest' THEN CONCAT('http://ui.subsidiesysteem.local/status-overeenkomst/', @DeclarationID, '?employerNumber=', @EmployerNumber)
						WHEN DB_NAME() = 'OTIBDS_Acceptatie' THEN CONCAT('https://acceptatie.otib-online.nl/status-overeenkomst/', @DeclarationID, '?employerNumber=', @EmployerNumber)
				   END

	SET @Recipients = REPLACE(@Email, '&' , '&amp;')

	SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
	SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

	SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', ISNULL(@Recipients, ''))
	SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%EmailSentDate%>', ISNULL(CONVERT(varchar(10), @EmailSentDate, 105), ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%ResponseDate%>', ISNULL(CONVERT(varchar(10), DATEADD(WW, 3, @EmailSentDate), 105), ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%LinkURL%>', ISNULL(@LinkURL, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%MailBanner%>', ISNULL(@MailBanner, ''))

	-- Insert record into eml.tblEmail.
	--INSERT INTO eml.tblEmail
	--	(
	--		EmailHeaders,
	--		EmailBody,
	--		CreationDate,
	--		SentDate
	--	)
	--VALUES
	--	(	'<headers>'
	--		+ '<header key="subject" value="Stimuleringsregeling Praktijkbegeleiding (STIP); status van de opleiding" />'
	--		+ '<header key="to" value="' + REPLACE(@Email, '&', '&amp;') + '" />'
	--		+ '</headers>',
	--		'<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>' + 
	--		'Geachte mevrouw, heer,<br>' +
	--		'<br>' +
	--		'Op ' + CONVERT(varchar(10), @EmailSentDate, 105)  + ' jl. hebben wij u laten weten dat u, volgens onze gegevens, <br>' + 
	--		'op basis van de Stimuleringsregeling Praktijkbegeleiding (STIP) - <br>' +
	--		'een bijdrage in de kosten van de begeleiding van leerling-werknemers door een praktijkopleider - recht heeft op een vergoeding.<br>' +
	--		'<br>' +
	--		'Om te kunnen beoordelen of u ook daadwerkelijk voor deze vergoeding in aanmerking komt, vragen wij u <a href="' + @LinkURL + 
	--		'">hier</a> aan te geven of uw werknemer:<br>' +
	--		'<br>' +
	--		'a.	Nog bezig is met de opleiding.<br>' +
	--		'b.	Is geslaagd. Dan ontvangen wij graag binnen een half jaar na diplomadatum een kopie van het diploma.<br>' +
	--		'c.	Is gestopt met de opleiding.<br>' +
	--		'd.	Uit dienst is.<br>' +
	--		'<br>' +
	--		'Wij attenderen u er op dat wij nog geen reactie van u ontvangen hebben. ' +
	--		'Wij verzoeken u voor ' + CONVERT(varchar(10), DATEADD(WW, 3, @EmailSentDate), 105) + ' de status aan ons door te geven. ' +
	--		'Als wij op ' + CONVERT(varchar(10), DATEADD(WW, 3, @EmailSentDate), 105) + ' deze informatie niet hebben ontvangen, ' +
	--		'vervalt het recht op betaling van de tegemoetkoming.<br>' +
	--		'<br>' +
	--		'Voor nadere informatie over de STIP kunt u <a href="www.otib.nl">www.otib.nl</a> of <a href="www.otib-online.nl">www.otib-online.nl</a> raadplegen.<br>' +
	--		'<br><br>' +			
	--		'Met vriendelijke groet,<br>' +
	--		'OTIB<br>' +
	--		'<a href="mailto:support@otib.nl">support@otib.nl</a><br>' +
	--		'T 0800 885 58 85<br>' +
	--		'<img src="' + @MailBanner + '" width="450" style="border: none;" />' +
	--		'</p>',
	--		@LogDate,
	--		'20991231'
	--	)

		INSERT INTO eml.tblEmail
			(
				EmailHeaders,
				EmailBody,
				CreationDate,
				SentDate
			)
		VALUES
			(
				@EmailHeader,
				@EmailBody,
				@Creation_DateTime,
				'20991231'
			)

	-- Retrieve added ID
	SET	@EmailID = SCOPE_IDENTITY()

	-- Insert record into stip.tblEmail_Partition.
	INSERT INTO stip.tblEmail_Partition
		(
			EmailID,
			PartitionID,
			LetterType
		)
	VALUES
		(
			@EmailID,
			@PartitionID,
			2
		)

	FETCH NEXT FROM cur_Email2 INTO @DeclarationID, @PartitionID, @Email, @EmailSentDate, @EmployerNumber
END

CLOSE cur_Email2
DEALLOCATE cur_Email2

-- Insert e-mail 3 for sending.
-- Een derde e-mail wordt na drie weken verstuurd (indien geen reactie op tweede e-mail).
DECLARE cur_Email3 CURSOR FOR 
	SELECT	d.DeclarationID,
			dep.PartitionID,
			eme.Email,
			eml.SentDate,
			d.EmployerNumber
	FROM	stip.tblEmail_Partition epa1
	INNER JOIN stip.tblEmail_Partition epa2
	ON		epa2.PartitionID = epa1.PartitionID
	INNER JOIN sub.tblDeclaration_Partition dep
	ON		dep.PartitionID = epa2.PartitionID
	INNER JOIN sub.tblDeclaration d
	ON		d.DeclarationID = dep.DeclarationID
	INNER JOIN sub.viewEmployerEmail eme
	ON		eme.EmployerNumber = d.EmployerNumber
	INNER JOIN eml.tblEmail eml
	ON		eml.EmailID = epa1.EmailID
	LEFT JOIN stip.tblEmail_Partition epa3
	ON		epa3.PartitionID = dep.PartitionID
	AND		epa3.LetterType = 3
	WHERE	dep.PartitionStatus = @PartitionStatus
	AND		epa1.LetterType = 1
	AND		epa2.LetterType = 2
	AND		epa1.ReplyDate IS NULL
	AND		epa2.ReplyDate IS NULL
	AND		CAST(DATEADD(WW, 3, eml.SentDate) AS date) <= CAST(@LogDate AS date)
	AND		dep.PartitionStatus = '0026'
	AND		epa3.EmailID IS NULL


OPEN cur_Email3
FETCH FROM cur_Email3 INTO @DeclarationID, @PartitionID, @Email, @EmailSentDate, @EmployerNumber

SET @TemplateID = 13

WHILE @@FETCH_STATUS = 0  
BEGIN

	SET @Recipients = REPLACE(@Email, '&' , '&amp;')

	SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
	SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

	SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', ISNULL(@Recipients, ''))
	SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%EmailSentDate%>', ISNULL(CONVERT(varchar(10), @EmailSentDate, 105), ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%MailBanner%>', ISNULL(@MailBanner, ''))

	-- Insert record into eml.tblEmail.
	--INSERT INTO eml.tblEmail
	--	(
	--		EmailHeaders,
	--		EmailBody,
	--		CreationDate,
	--		SentDate
	--	)
	--VALUES
	--	(	'<headers>'
	--		+ '<header key="subject" value="Stimuleringsregeling Praktijkbegeleiding (STIP); betaling tegemoetkoming vervalt" />'
	--		+ '<header key="to" value="' + REPLACE(@Email, '&', '&amp;') + '" />'
	--		+ '</headers>',
	--		'<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>' + 
	--		'Geachte mevrouw, heer,<br>' +
	--		'<br>' +
	--		'Volgens onze gegevens heeft u op basis van de Stimuleringsregeling Praktijkbegeleiding (STIP) - ' + 
	--		'een bijdrage in de kosten van de begeleiding van leerling-werknemers door een praktijkopleider - recht op de een vergoeding. ' +
	--		'Wij hebben u inmiddels twee keer benaderd met het verzoek ons voor ' + CONVERT(varchar(10), @EmailSentDate, 105)  + 
	--		' te informeren over de stand van zaken ten aanzien van de opleiding van uw leerling-werknemer.<br>' +
	--		'<br>' +
	--		'Wij hebben geen reactie van u ontvangen binnen de gestelde termijn van drie weken, ' +
	--		'waarmee het recht op betaling van de tegemoetkoming vervalt.<br>' +
	--		'<br>' +
	--		'Voor nadere informatie over de STIP kunt u <a href="www.otib.nl">www.otib.nl</a> of <a href="www.otib-online.nl">www.otib-online.nl</a> raadplegen.<br>' +
	--		'<br><br>' +			
	--		'Met vriendelijke groet,<br>' +
	--		'OTIB<br>' +
	--		'<a href="mailto:support@otib.nl">support@otib.nl</a><br>' +
	--		'T 0800 885 58 85<br>' +
	--		'<img src="' + @MailBanner + '" width="450" style="border: none;" />' +
	--		'</p>',
	--		@LogDate,
	--		'20991231'
	--	)

		INSERT INTO eml.tblEmail
			(
				EmailHeaders,
				EmailBody,
				CreationDate,
				SentDate
			)
		VALUES
			(
				@EmailHeader,
				@EmailBody,
				@Creation_DateTime,
				'20991231'
			)

	-- Retrieve added ID
	SET	@EmailID = SCOPE_IDENTITY()

	-- Insert record into stip.tblEmail_Partition.
	INSERT INTO stip.tblEmail_Partition
		(
			EmailID,
			PartitionID,
			LetterType
		)
	VALUES
		(
			@EmailID,
			@PartitionID,
			3
		)

	-- Update the declaration- and partitionstatus.
	SELECT	@DeclarationStatus = '0035',
			@PartitionStatus = '0029'

	EXECUTE @RC = sub.uspDeclaration_Upd_DeclarationStatus 
		@DeclarationID,
		@DeclarationStatus,
		@StatusReason,
		@CurrentUserID

	EXECUTE @RC = sub.uspDeclaration_Partition_Upd_PartitionStatus 
		@PartitionID,
		@PartitionStatus,
		@CurrentUserID

	FETCH NEXT FROM cur_Email3 INTO @DeclarationID, @PartitionID, @Email, @EmailSentDate, @EmployerNumber
END

CLOSE cur_Email3
DEALLOCATE cur_Email3

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspProcessReferenceDate ===========================================================	*/
