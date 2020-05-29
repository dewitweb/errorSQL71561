CREATE PROCEDURE [sub].[uspPaymentRun_Export]
@PaymentRunID	int = 0
AS
/*	==========================================================================================
	Purpose:	Create new export files for Exact in xml format.

	Note:		This procedure will export a specific paymentrun 
				or all the paymentruns that have not been exported yet.
				
				If a file needs to be created again then the ExportDate 
				in the relevant PaymentRun should by set to NULL.

	06-01-2020	Jaap van Assenbergh	OTIBSUB-1798	Banner per period or default
	02-01-2020	Sander van Houten	OTIBSUB-1793	Added check on errors in the exported XML.
	24-04-2019  Sander van Houten	OTIBSUB-1013	Performance enhancements PaymentRun.
	16-04-2019	Sander van Houten	OTIBSUB-971		Split-up paymentrun, e-mail sending and 
										export to Exact.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

DECLARE @Creation_DateTime  datetime = GETDATE()
DECLARE @TemplateID			int = 26
DECLARE @EmailHeader		varchar(MAX),
		@EmailBody			varchar(MAX),
		@SubjectAddition	varchar(100) = '',
		@Recipients			varchar(MAX),
		@Reason				varchar(MAX)

DECLARE @RC	        int,
		@MailBanner varchar(100)

DECLARE cur_PaymentRun CURSOR FOR 
	SELECT 	PaymentRunID
	FROM	sub.tblPaymentRun
	WHERE	PaymentRunID = @PaymentRunID
	   OR	(	@PaymentRunID = 0 
		AND		PaymentRunID > 60000 
		AND		ExportDate IS NULL 
		AND		Completed IS NOT NULL
			)

OPEN cur_PaymentRun

FETCH NEXT FROM cur_PaymentRun INTO @PaymentRunID

WHILE @@FETCH_STATUS = 0  
BEGIN
	EXECUTE @RC = sub.uspPaymentRun_ExportToTable @PaymentRunID
	
    IF @RC = 0  -- There can be no errors in the data.
    BEGIN
        EXECUTE @RC = sub.uspPaymentRun_ExportToFile @PaymentRunID

        /*	If the procedure is executed in the production environment 
            then send e-mails to employers.	*/
        IF EXISTS(SELECT 1 FROM sys.servers WHERE NAME = N'HORUS_P') AND DB_NAME() = 'OTIBDS'
        BEGIN
            EXECUTE @RC = sub.uspPaymentRun_SendEmail @PaymentRunID
        END
    END
    ELSE
    BEGIN   -- If an error is detected in the export data an e-mail is send to the Ambition IT supportdesk.
        -- Get MailBanner location.
		SELECT	@MailBanner = COALESCE(apse.SettingValue, aps.SettingValue)
		FROM	sub.tblApplicationSetting aps
		LEFT JOIN sub.tblApplicationSetting_Extended apse 
			ON	apse.ApplicationSettingID = aps.ApplicationSettingID 
			AND	GETDATE() BETWEEN apse.StartDate AND apse.EndDate
		WHERE	aps.SettingName = 'BaseURL'
		AND		aps.SettingCode = 'AssetsMailBanner'

		SET @Recipients = 'support@ambitionit.nl;svanhouten@ambitionit.nl;jvanassenbergh@ambitionit.nl'
		SET @SubjectAddition = 
			' (' +	CASE 
						WHEN DB_NAME() = 'OTIBDS' THEN 'PRD'
						WHEN DB_NAME() = 'OTIBDSTest' THEN 'TST'
						WHEN DB_NAME() = 'OTIBDS_Acceptatie' THEN 'ACC'
		                ELSE '' 
					END + ')'

		SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
		SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

		SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', ISNULL(@Recipients, ''))
		SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))

		SET @EmailBody = REPLACE(@EmailBody, '<%RC%>', ISNULL(CAST(@RC AS varchar(2)), ''))
		SET @EmailBody = REPLACE(@EmailBody, '<%PaymentRunID%>', ISNULL(CAST(@PaymentRunID AS varchar(18)), ''))
		SET @EmailBody = REPLACE(@EmailBody, '<%MailBanner%>', ISNULL(@MailBanner, ''))

        --INSERT INTO eml.tblEmail
        --            (EmailHeaders,
        --            EmailBody,
        --            CreationDate,
        --            SentDate)
        --SELECT	'<headers>'
        --        + '<header key="subject" value="OTIB Online: Fout geconstateerd in de betalingsrun export data (' 
        --        + CASE 
        --            WHEN DB_NAME() = 'OTIBDS' THEN 'PRD'
        --            WHEN DB_NAME() = 'OTIBDSTest' THEN 'TST'
        --            WHEN DB_NAME() = 'OTIBDS_Acceptatie' THEN 'ACC'
        --            ELSE ''
        --        END
        --        + ')" />'
        --        + '<header key="to" value="support@ambitionit.nl;svanhouten@ambitionit.nl;jvanassenbergh@ambitionit.nl" />'
        --        + '</headers>'  AS EmailHeaders,
        --        '<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>Beste afdeling Support,<br>' 
        --        + '<br>' 
        --        + 'Er is een fout (code ' + CAST(@RC AS varchar(2))
        --        + ') geconstateerd in de data voor de export van de betalingsrun met ID ' 
        --        + CAST(@PaymentRunID AS varchar(18)) + '.<br>'
        --        + 'Het fysieke bestand is hierdoor niet aangemaakt en de bijbehorende e-mails zijn ook niet verstuurd.<br>'
        --        + 'Gelieve hier met enige urgentie naar te kijken.<br>'
        --        + '<br><br>' 
        --        + 'Met vriendelijke groet,<br>' 
        --        + 'OTIB<br>'
        --        + '<a href="mailto:support@otib.nl">support@otib.nl</a><br>' 
        --        + 'T 0800 885 58 85<br>' 
        --        + '<img src="' + @MailBanner + '" width="450" style="border: none;" />' 
        --        + '</p>'		AS EmailBody,
        --        GETDATE()		AS CreationDate,
        --        NULL			AS SentDate

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

	FETCH NEXT FROM cur_PaymentRun INTO @PaymentRunID
END

CLOSE cur_PaymentRun
DEALLOCATE cur_PaymentRun

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspPaymentRun_Export===============================================================	*/

