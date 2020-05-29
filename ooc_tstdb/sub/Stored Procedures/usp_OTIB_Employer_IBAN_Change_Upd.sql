
CREATE PROCEDURE [sub].[usp_OTIB_Employer_IBAN_Change_Upd]
@IBANChangeID		int,
@Accept				bit,
@RejectionReason	varchar(4),
@CurrentUserID		int = 1
AS
/*	==========================================================================================
	Purpose:	Update sub.tblEmployer_IBAN_Change on the basis of IBANChangeID.

	Notes:		ChangeStatus	0001 = Firstcheck Accepted
								0002 = Firstcheck Rejected
								0003 = Firstcheck Accepted, Secondcheck Rejected
								0004 = Firstcheck Accepted, Secondcheck Accepted

	06-01-2020	Jaap van Assenbergh	OTIBSUB-1798	Banner per period or default
	26-04-2019	Sander van Houten	OTIBSUB-1021	Send an e-mail to financial department.
	24-04-2019	Sander van Houten	OTIBSUB-1011	Use of an ampersand (&) in an e-mailaddress
											gives xml-parsing error.
	02-04-2019	Sander van Houten	OTIBSUB-874		E-mail design changes.
	25-03-2019	Sander van Houten	Domain change to otib-online.nl (OTIBSUB-694).
	14-02-2019	Sander van Houten	Update after decision on 4-eye principle check (OTIBSUB-699).
	14-12-2018	Sander van Houten	IBAN, na goedkeuring doorgeven aan Horus (OTIBSUB-489).
	19-11-2018	Sander van Houten	Initial version (OTIBSUB-98).
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata
DECLARE	@IBANChangeID		int = 1,
		@Accept				bit = 1,
		@CurrentUserID		int = 1
--*/
DECLARE @Creation_DateTime  datetime = GETDATE()
DECLARE @TemplateID			int
DECLARE @EmailHeader		varchar(MAX),
		@EmailBody			varchar(MAX),
		@SubjectAddition	varchar(100) = '',
		@Recipients			varchar(MAX),
		@Reason				varchar(MAX)

DECLARE @XMLdel		xml,
		@XMLins		xml,
		@LogDate	datetime = GETDATE(),
		@KeyID		varchar(50)

DECLARE @ChangeStatus	varchar(4),
		@SQL			varchar(MAX),
		@Result			varchar(8000),
		@EmployerNumber	varchar(6),
		@EmployerName	varchar(100),
		@IBAN_New		varchar(34),
		@IBAN_Old		varchar(34),
		@StartDate		date,
		@MailBanner		varchar(100),
		@Email			varchar(50)
		
-- Initialize @Accept.
IF @Accept IS NULL
	SET @Accept = 0

-- Save old record.
SELECT	@XMLdel = (SELECT * 
					FROM   sub.tblEmployer_IBAN_Change
					WHERE  IBANChangeID = @IBANChangeID
					FOR XML PATH)

-- Update exisiting record.
UPDATE	sub.tblEmployer_IBAN_Change
SET
		FirstCheck_UserID		= CASE ISNULL(FirstCheck_UserID, 0) 
									WHEN 0 THEN @CurrentUserID
									ELSE FirstCheck_UserID
									END,
		FirstCheck_DateTime		= CASE ISNULL(FirstCheck_UserID, 0) 
									WHEN 0 THEN GETDATE()
									ELSE FirstCheck_DateTime
									END,
		SecondCheck_UserID		= CASE ISNULL(FirstCheck_UserID, 0)
									WHEN 0 THEN SecondCheck_UserID
									ELSE @CurrentUserID
									END,
		SecondCheck_DateTime	= CASE ISNULL(FirstCheck_UserID, 0) 
									WHEN 0 THEN SecondCheck_DateTime
									ELSE GETDATE()
									END,
		ChangeStatus			= CASE ISNULL(FirstCheck_UserID, 0)
									WHEN 0 THEN CASE @Accept
													WHEN 1 THEN '0001'
													ELSE '0002'
												END
									ELSE CASE @Accept
											WHEN 0 THEN '0003'
											ELSE '0004'
										 END
									END,
		@ChangeStatus			= CASE ISNULL(FirstCheck_UserID, 0)
									WHEN 0 THEN CASE @Accept
													WHEN 1 THEN '0001'
													ELSE '0002'
												END
									ELSE CASE @Accept
											WHEN 0 THEN '0003'
											ELSE '0004'
										 END
									END,
		RejectionReason			= @RejectionReason,
		@IBAN_New				= IBAN_New,
		@EmployerNumber			= EmployerNumber
WHERE	IBANChangeID = @IBANChangeID

-- Get MailBanner location.
SELECT	@MailBanner = COALESCE(apse.SettingValue, aps.SettingValue)
FROM	sub.tblApplicationSetting aps
LEFT JOIN sub.tblApplicationSetting_Extended apse 
	ON	apse.ApplicationSettingID = aps.ApplicationSettingID 
	AND	GETDATE() BETWEEN apse.StartDate AND apse.EndDate
WHERE	aps.SettingName = 'BaseURL'
AND		aps.SettingCode = 'AssetsMailBanner'

/* Give feedback to declarant through e-mail.	*/
IF @ChangeStatus >= '0002'
BEGIN

	SELECT	@Email = emp.Email, 
			@StartDate = eic.StartDate,
			@Reason = aps.SettingValue
	FROM	sub.tblEmployer_IBAN_Change eic
	INNER JOIN	sub.viewEmployerEmail emp 
			ON	emp.EmployerNumber = eic.EmployerNumber
	LEFT JOIN	sub.tblApplicationSetting aps 
			ON	aps.SettingName = 'IBANRejectionReason' 
			AND	aps.SettingCode = eic.RejectionReason
	WHERE	eic.IBANChangeID = @IBANChangeID

	IF	ISNULL(@Reason, '') = ''
	BEGIN
		IF @StartDate <= @LogDate
		BEGIN
			SET @TemplateID = 19
			SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
			SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

		END
		ELSE
		BEGIN
			SET @TemplateID = 20
			SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
			SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

			SET @EmailBody = REPLACE(@EmailBody, '<%StartDate%>', CONVERT(varchar(10), @StartDate, 105))
		END
	END
	ELSE
	BEGIN
		SET @TemplateID = 21
		SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
		SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

		SET @EmailBody = REPLACE(@EmailBody, '<%Reason%>', ISNULL(@Reason, ''))
	END 

	SET @Recipients = REPLACE(@Email, '&' , '&amp;')
	SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', ISNULL(@Recipients, ''))
	SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%MailBanner%>', ISNULL(@MailBanner, ''))

	-- Insert e-mail for sending.
	--INSERT INTO eml.tblEmail
	--		   (EmailHeaders
	--		   ,EmailBody
	--		   ,CreationDate)
	--SELECT	'<headers>'
	--		+ '<header key="subject" value="OTIB Online: Aanvraag IBAN wijziging" />'
	--		+ '<header key="to" value="' + REPLACE(emp.Email, '&', '&amp;') + '" />'
	--		+ '</headers>'	AS EmailHeaders,
	--		'<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>' + 
	--		CASE WHEN eic.RejectionReason IS NULL 
	--			THEN CASE WHEN eic.StartDate <= CAST(@LogDate AS date)
	--						THEN 'Uw aanvraag voor de IBAN wijziging is goedgekeurd en verwerkt in het systeem.<br>' 
	--						ELSE 'Uw aanvraag voor de IBAN wijziging is goedgekeurd en wordt op '
	--							 + CONVERT(varchar(10), eic.StartDate, 105) + ' verwerkt in het systeem.<br>'
	--				 END
	--			ELSE 'Uw aanvraag voor de IBAN wijziging is niet goedgekeurd.<br>' +
	--				 'De reden hiervoor is: ' + aps.SettingValue + '.<br><br>' +
	--				 'Bij vragen omtrent deze afkeuring kunt u contact opnemen met de OTIB supportdesk, 0800-8855885.<br>'
	--		END +
	--		'<br><br>' +			'Met vriendelijke groet,<br>' +
	--		'OTIB<br>' +
	--		'<a href="mailto:support@otib.nl">support@otib.nl</a><br>' +
	--		'T 0800 885 58 85<br>' +
	--		'<img src="' + @MailBanner + '" width="450" style="border: none;" />' +
	--		'</p>'			AS EmailBody,
	--		@LogDate		AS CreationDate
	--FROM	sub.tblEmployer_IBAN_Change eic
	--INNER JOIN sub.viewEmployerEmail emp ON emp.EmployerNumber = eic.EmployerNumber
	--LEFT JOIN sub.tblApplicationSetting aps ON aps.SettingName = 'IBANRejectionReason' AND aps.SettingCode = eic.RejectionReason
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
END

IF @ChangeStatus = '0004'
BEGIN
	IF @StartDate <= CAST(@LogDate AS date)
	BEGIN
		-- Update IBAN in OTIB-DS.
		UPDATE	sub.tblEmployer
		SET		IBAN = @IBAN_New
		WHERE	EmployerNumber = @EmployerNumber

		UPDATE	sub.tblEmployer_IBAN_Change
		SET		ChangeExecutedOn = @LogDate
		WHERE	IBANChangeID = @IBANChangeID

		IF EXISTS(SELECT 1 FROM sys.servers WHERE NAME = N'HORUS_P')
		BEGIN	
			-- Update IBAN in Horus.
			SET	@SQL = 'BEGIN ? :=OLCOWNER.HRS_PCK_OTIBDS.WGR_WIJZIG_IBAN('
						+ '''' + @EmployerNumber + ''', '
						+ '''' + @IBAN_New + ''''
						+ '); END;'

			IF DB_NAME() = 'OTIBDS'
				EXEC(@SQL, @Result OUTPUT) AT HORUS_P
			ELSE
				EXEC(@SQL, @Result OUTPUT) AT HORUS_A
		END
	END

	-- Give feedback to financial department through an e-mail (OTIBSUB-1021).
	-- This e-mail should only be send if the change is accepted within 3 workdays
	-- after a paymentrun is processed to which the employer was linked.
	IF @StartDate < CAST(@LogDate AS date)
		SET @StartDate = CAST(@LogDate AS date)

	SET @Recipients = 'r.rijnsburger@otib.nl'

	SELECT	DISTINCT
			@EmployerNumber = emp.EmployerNumber,
			@EmployerName = emp.EmployerName,
			@IBAN_Old = eic.IBAN_Old,
			@IBAN_New = eic.IBAN_New 
	FROM	sub.tblEmployer_IBAN_Change eic
	INNER JOIN	sub.tblEmployer emp 
			ON	emp.EmployerNumber = eic.EmployerNumber
	INNER JOIN	sub.tblDeclaration decl 
			ON	decl.EmployerNumber = eic.EmployerNumber
	INNER JOIN	sub.tblPaymentRun_Declaration pad 
			ON	pad.DeclarationID = decl.DeclarationID
	INNER JOIN	sub.tblPaymentRun par 
			ON	par.PaymentRunID = pad.PaymentRunID
	WHERE	eic.IBANChangeID = @IBANChangeID
	AND		( SELECT DATEDIFF(Day, par.ExportDate, @StartDate) -- Total Days
					- (DATEDIFF(Day, 0, @StartDate)/7 - DATEDIFF(Day, 0, par.ExportDate)/7) -- Sundays
					- (DATEDIFF(Day, -1, @StartDate)/7 - DATEDIFF(Day, -1, par.ExportDate)/7) -- Saturdays
			) <= 3  

	SET @TemplateID = 22
	SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
	SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

	SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', ISNULL(@Recipients, ''))
	SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))

	SET @EmailBody = REPLACE(@EmailBody, '<%EmployerNumber%>', ISNULL(@EmployerNumber, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%EmployerName%>', ISNULL(@EmployerName, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%IBAN_Old%>', ISNULL(@IBAN_Old, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%IBAN_New%>', ISNULL(@IBAN_New, ''))
	SET @EmailBody = REPLACE(@EmailBody, '<%MailBanner%>', ISNULL(@MailBanner, ''))

	--INSERT INTO eml.tblEmail
	--			(EmailHeaders
	--			,EmailBody
	--			,CreationDate)
	--SELECT	DISTINCT
	--		'<headers>'
	--		+ '<header key="subject" value="OTIB Online: Goedkeuring aanvraag IBAN wijziging" />'
	--		+ '<header key="to" value="r.rijnsburger@otib.nl" />'
	--		+ '</headers>'	AS EmailHeaders,
	--		'<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>' + 
	--		'Een aanvraag voor een IBAN wijziging is goedgekeurd en verwerkt in het systeem.<br>' +
	--		'Deze IBAN wijziging heeft betrekking op een uitbetaling die is verwerkt in een betalingsrun van minder dan 3 werkdagen geleden.<br>' + 
	--		'De gegevens luiden als volgt:<br><br>' +
	--		'<pre>Werkgevernummer:         ' + emp.EmployerNumber + '</pre>' +
	--		'<pre>Werkgevernaam:           ' + emp.EmployerName + '</pre>' +
	--		'<pre>Oude IBAN nummer:        ' + eic.IBAN_Old + '</pre>' +
	--		'<pre>Nieuwe IBAN nummer:      ' + eic.IBAN_New + '</pre>' +
	--		'<br><br>' +			'Met vriendelijke groet,<br>' +
	--		'OTIB<br>' +
	--		'<a href="mailto:support@otib.nl">support@otib.nl</a><br>' +
	--		'T 0800 885 58 85<br>' +
	--		'<img src="' + @MailBanner + '" width="450" style="border: none;" />' +
	--		'</p>'			AS EmailBody,
	--		@LogDate		AS CreationDate
	--FROM	sub.tblEmployer_IBAN_Change eic
	--INNER JOIN sub.tblEmployer emp ON emp.EmployerNumber = eic.EmployerNumber
	--INNER JOIN sub.tblDeclaration decl ON decl.EmployerNumber = eic.EmployerNumber
	--INNER JOIN sub.tblPaymentRun_Declaration pad ON pad.DeclarationID = decl.DeclarationID
	--INNER JOIN sub.tblPaymentRun par ON par.PaymentRunID = pad.PaymentRunID
	--WHERE	eic.IBANChangeID = @IBANChangeID
	--AND		( SELECT DATEDIFF(Day, par.ExportDate, @StartDate) -- Total Days
	--				- (DATEDIFF(Day, 0, @StartDate)/7 - DATEDIFF(Day, 0, par.ExportDate)/7) -- Sundays
	--				- (DATEDIFF(Day, -1, @StartDate)/7 - DATEDIFF(Day, -1, par.ExportDate)/7) -- Saturdays
	--		) <= 3  

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

-- Save new record.
SELECT	@XMLins = (SELECT * 
					FROM   sub.tblEmployer_IBAN_Change
					WHERE  IBANChangeID = @IBANChangeID
					FOR XML PATH)

-- Log action in tblHistory.
IF @@ROWCOUNT > 0
BEGIN
	SET @KeyID = CAST(@IBANChangeID AS varchar(18))

	EXEC his.uspHistory_Add
			'sub.tblEmployer_IBAN_Change',
			@KeyID,
			@CurrentUserID,
			@LogDate,
			@XMLdel,
			@XMLins
END

SELECT	IBANChangeID = @IBANChangeID

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.usp_OTIB_Employer_IBAN_Change_Upd =====================================	*/
