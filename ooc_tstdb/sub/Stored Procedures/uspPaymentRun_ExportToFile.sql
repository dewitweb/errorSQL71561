CREATE PROCEDURE [sub].[uspPaymentRun_ExportToFile]
@PaymentRunID	int = 0
AS
/*	==========================================================================================
	Purpose:	Create new fysical export files for Exact.

	Parameter:	@PaymentRunID
	
	Note:		If a PaymentRunID is given, only the files for that specific PaymentRun 
				will be created.
				Otherwise all PaymentRuns that have not been exported to files will be processed.

	31-01-2020	Sander van Houten		OTIBSUB-1837	Changed addresses for e-mail sending.
	13-11-2019	Sander van Houten		OTIBSUB-1683	Removed address of i.rietveld for EVC.
	06-11-2019	Sander van Houten		OTIBSUB-1683	Removed duplicate address of i.rietveld.
	02-10-2019	Sander van Houten		OTIBSUB-1539	Removed @DeclarationStatus.
	02-09-2019	Sander van Houten		OTIBSUB-1521	Added email address of i.rietveld.
	16-04-2019	Sander van Houten		OTIBSUB-971		Split up paymentrun, 
										    -mail sending and export to Exact.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	Testdata.
DECLARE @PaymentRunID	int = 60001
--	*/

/* Declare variables.	*/
DECLARE	@SubsidySchemeID		int,
		@SubsidySchemeName		varchar(50),
		@XMLPayments			xml,
		@XMLCreditors			xml,
		@GLAccount				varchar(5),
		@LastJournalEntryCode	int,
		@JournalCode			varchar(10),
		@PaymentRunEndDate		date,
		@MailBanner				varchar(100)

DECLARE	@FilePath			varchar(255),
		@FileName			varchar(100),
		@String				varchar(max)
	
DECLARE @tblPaymentRun TABLE 
	(
		PaymentRunID	int
	)

--	Get export file path.
SELECT	@FilePath = SettingValue
FROM	sub.tblApplicationSetting
WHERE	SettingName = 'ExactExportFilePath'
	AND	SettingCode = '0000'

-- Get MailBanner location.
SELECT	@MailBanner = COALESCE(apse.SettingValue, aps.SettingValue)
FROM	sub.tblApplicationSetting aps
LEFT JOIN sub.tblApplicationSetting_Extended apse 
	ON	apse.ApplicationSettingID = aps.ApplicationSettingID 
	AND	GETDATE() BETWEEN apse.StartDate AND apse.EndDate
WHERE	aps.SettingName = 'BaseURL'
AND		aps.SettingCode = 'AssetsMailBanner'

/*	Get PaymentRunID(s) to be processed.	*/
INSERT INTO @tblPaymentRun 
	(
		PaymentRunID
	) 
SELECT	DISTINCT
		PaymentRunID
FROM	sub.tblPaymentRun_XMLExport
WHERE	(	@PaymentRunID = 0
  AND		ExportDate IS NULL )
   OR	(	@PaymentRunID <> 0
  AND		PaymentRunID = @PaymentRunID )

/*	Create cursor on bases of @tblPaymentRun.	*/
DECLARE cur_PaymentRunExport CURSOR FOR 
	SELECT 	PaymentRunID
	FROM	@tblPaymentRun
		
OPEN cur_PaymentRunExport

FETCH NEXT FROM cur_PaymentRunExport INTO @PaymentRunID

--	Process the PaymentRun(s).
WHILE @@FETCH_STATUS = 0
BEGIN
	--	Get the data needed for the export.
	SELECT	@XMLCreditors = pxe.XMLCreditors,
			@XMLPayments = pxe.XMLPayments,
			@SubsidySchemeName = SubsidySchemeName,
			@PaymentRunEndDate = par.EndDate
	FROM	sub.tblPaymentRun_XMLExport pxe
	INNER JOIN sub.tblPaymentRun par ON par.PaymentRunID = pxe.PaymentRunID
	INNER JOIN sub.tblSubsidyScheme sus ON sus.SubsidySchemeID = par.SubsidySchemeID
	WHERE	pxe.PaymentRunID = @PaymentRunID

	--	Create the xml file for the creditordata.
	SELECT	@FileName = REPLACE(
								REPLACE(SettingValue, 
											'<PaymentRunID>', 
											@PaymentRunID
										),
								'<SubsidySchemeName>',
								LOWER(@SubsidySchemeName)
								)
	FROM	sub.tblApplicationSetting
	WHERE	SettingName = 'ExactExportFileName'
		AND	SettingCode = 'Creditors'

	--	Cast xml to string format.
	SET @String = '<?xml version="1.0" encoding="ISO-8859-1"?>' + CAST(@XMLCreditors AS varchar(max))

	-- Write the fysical file.
	EXEC [ait].[uspWriteStringToFile] @String, @FilePath, @FileName

	--	Create the xml file for the paymentdata.
	SELECT	@FileName = REPLACE(
								REPLACE(SettingValue, 
											'<PaymentRunID>', 
											@PaymentRunID
										),
								'<SubsidySchemeName>',
								LOWER(@SubsidySchemeName)
								)
	FROM	sub.tblApplicationSetting
	WHERE	SettingName = 'ExactExportFileName'
		AND	SettingCode = 'Declarations'

	--	Cast xml to string format.
	SET @String = CAST(@XMLPayments AS varchar(max))

	-- Write the fysical file.
	EXEC [ait].[uspWriteStringToFile] @String, @FilePath, @FileName

	/* Update ExportDate of PaymentRun_XMLExport and of PaymentRun.	*/
	UPDATE	pxe
	SET		ExportDate = GETDATE()
	FROM	sub.tblPaymentRun_XMLExport pxe
	WHERE	pxe.PaymentRunID = @PaymentRunID

	UPDATE	par
	SET		ExportDate = GETDATE()
	FROM	sub.tblPaymentRun par
	WHERE	par.PaymentRunID = @PaymentRunID

	/* Give feedback through e-mail (to OTIB-user and to OTIB finance).	*/
	INSERT INTO [eml].[tblEmail]
				([EmailHeaders]
				,[EmailBody]
				,[CreationDate]
				,[SentDate])
	SELECT	'<headers>'
			+ '<header key="subject" value="OTIB Online: ' + UPPER(@SubsidySchemeName) + ' betalingsrun status update" />'
			+ '<header key="to" value="r.rijnsburger@otib.nl;' + ISNULL(usr.Email, '')
			+ CASE WHEN @SubsidySchemeName = 'OSR'
                THEN CASE usr.Email
                        WHEN 's.vdwaaij@otib.nl' THEN ';i.rietveld@otib.nl;n.rossewij@otib.nl' 
                        WHEN 'i.rietveld@otib.nl' THEN ';s.vdwaaij@otib.nl;n.rossewij@otib.nl' 
                        WHEN 'n.rossewij@otib.nl' THEN ';s.vdwaaij@otib.nl;i.rietveld@otib.nl' 
                        ELSE ';s.vdwaaij@otib.nl;i.rietveld@otib.nl;n.rossewij@otib.nl'
                     END
                WHEN @SubsidySchemeName = 'EVC'
                THEN CASE usr.Email
                        WHEN 's.vdwaaij@otib.nl' THEN ';n.rossewij@otib.nl' 
                        WHEN 'n.rossewij@otib.nl' THEN ';s.vdwaaij@otib.nl' 
                        ELSE ';s.vdwaaij@otib.nl;n.rossewij@otib.nl'
                     END
                ELSE '' 
              END	--OTIBSUB-1521
			+ '" />'
            + '<header key="bcc" value="support@ambitionit.nl" />'
			+ '</headers>'	AS EmailHeaders,
			'<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>Beste afdeling Financiën,<br>' +
			'<br>' +
			'De ' + @SubsidySchemeName + ' betalingsrun is klaar en goed verlopen.<br>' + 
			'<br><br>' +
			'<table cellspacing="0" cellpadding="0" border="0" width="340">' +
			'<tr><td width="240">Batchnummer</td><td width="100">: ' + CAST(@PaymentRunID AS varchar(10)) + '</td></tr>' +
			'<tr><td width="240">Datum_uitkeringsrun_' + UPPER(@SubsidySchemeName) + '</td><td width="100">: ' + CONVERT(varchar(10), par.RunDate, 105) + '</td></tr>' +
			'<tr><td width="240">Datum_verwerken t/m</td><td width="100">: ' + CONVERT(varchar(10), @PaymentRunEndDate, 105) + '</td></tr>' +
			'<tr><td width="240">Aantal crediteuren</td><td width="100">: ' + CAST(pxe.NrOfCreditors AS varchar(6)) + '</td></tr>' +
			'<tr><td width="240">Aantal_declaraties_uitgekeerd</td><td width="100">: ' + CAST(pxe.NrOfDebits AS varchar(6)) + '</td></tr>' +
			'<tr><td width="240">Totaal_bedrag_uitgekeerd</td><td width="100">: ' + REPLACE(CAST(pxe.TotalAmountDebit AS varchar(20)), '.', ',') + '</td></tr>' +
			'<tr><td width="240">Max_notanummer</td><td width="100">: ' + pxe.LastJournalEntryCode + '</td></tr>' +
			'<tr><td width="240">Aantal declaraties teruggeboekt</td><td width="100">: ' + CAST(pxe.NrOfCredits AS varchar(6)) + '</td></tr>' +
			'<tr><td width="240">Totaal bedrag teruggeboekt</td><td width="100">: ' + REPLACE(CAST(pxe.TotalAmountCredit AS varchar(20)), '.', ',') + '</td></tr>' +
			'</table>' +
			'<br><br>' +
			'Het notabestand is aangemaakt met de naam : boekingen_' + LOWER(@SubsidySchemeName) + '_' + CAST(@PaymentRunID AS varchar(10)) + '_ADFOWNER.xml<br>' +
			'<br>' +
			'Het Exact bestand is aangemaakt met de naam : crediteuren_' + LOWER(@SubsidySchemeName) + '_' + CAST(@PaymentRunID AS varchar(10)) + '_ADFOWNER.xml<br>' +
			'<br><br>' +
			'Met vriendelijke groet,<br>' +
			'OTIB<br>' +
			'<a href="mailto:support@otib.nl">support@otib.nl</a><br>' +
			'T 0800 885 58 85<br>' +
			'<img src="' + @MailBanner + '" width="450" style="border: none;" />' +
			'</p>'				AS EmailBody,
			pxe.ExportDate		AS CreationDate,
			NULL				AS SentDate
	FROM	sub.tblPaymentRun par
	INNER JOIN sub.tblPaymentRun_XMLExport pxe ON pxe.PaymentRunID = par.PaymentRunID
	INNER JOIN auth.tblUser usr	ON usr.UserID = par.UserID
	WHERE	par.PaymentRunID = @PaymentRunID

	FETCH NEXT FROM cur_PaymentRunExport INTO @PaymentRunID
END

CLOSE cur_PaymentRunExport
DEALLOCATE cur_PaymentRunExport

/*	If the procedure is executed in the production environment 
	then copy the files to final destinations (Exact and Archive folders).	*/
IF EXISTS(SELECT 1 FROM sys.servers WHERE NAME = N'HORUS_P') AND DB_NAME() = 'OTIBDS'
BEGIN
	/*	Make sure the Ole Automation Procedures and xm_cmdshell options are accessable.	*/
	EXEC master.dbo.sp_configure 'show advanced options', 1
	RECONFIGURE
	EXEC master.dbo.sp_configure 'Ole Automation Procedures', 1
	RECONFIGURE;
	EXEC master.dbo.sp_configure 'xp_cmdshell', 1
	RECONFIGURE

	-- Copy the files to the Archive folder.
	DECLARE @cmdstr varchar(1000)
	SET		@cmdstr = 'copy ' + @FilePath + '\*.xml ' + @FilePath + '\Archive\*.xml'
	PRINT	@cmdstr
	EXEC xp_cmdshell @cmdstr

	-- Create a temporary drive for the HORUS-share.
	EXEC master..Xp_cmdshell 'net use X: "\\10.33.33.42\XMLExact$" /USER:DBHORUSP\DBuserDS "SwSArS9H59Up3WzE"'

	-- Move the files to the HORUS shared folder.
	SET		@cmdstr = 'move ' + @FilePath + '\*.xml X:\'
	PRINT	@cmdstr
	EXEC xp_cmdshell @cmdstr

	-- Disconnect the temporary drive.
	EXEC master..Xp_cmdshell 'net use /d X:'   --- To disconnect the mapped drive

	/*	Disable the Ole Automation Procedures and xp_cmdshell options.	*/
	EXEC master.dbo.sp_configure 'xp_cmdshell', 0
	RECONFIGURE
	EXEC master.dbo.sp_configure 'Ole Automation Procedures', 0
	RECONFIGURE;
	EXEC master.dbo.sp_configure 'show advanced options', 0
	RECONFIGURE
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/*	== sub.uspPaymentRun_ExportToFile=========================================================	*/
