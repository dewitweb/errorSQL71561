CREATE TABLE [sub].[tblApplicationSetting] (
    [ApplicationSettingID] INT           IDENTITY (1, 1) NOT NULL,
    [SettingName]          VARCHAR (50)  NOT NULL,
    [SettingCode]          VARCHAR (24)  NOT NULL,
    [ApplicationID]        INT           NOT NULL,
    [SettingValue]         VARCHAR (100) NOT NULL,
    [SettingDescription]   VARCHAR (MAX) NULL,
    [SortOrder]            TINYINT       NULL,
    CONSTRAINT [PK_sub_tblApplicationSetting] PRIMARY KEY CLUSTERED ([ApplicationSettingID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [UI_sub_tblApplicationSetting_Name_Code]
    ON [sub].[tblApplicationSetting]([SettingName] ASC, [SettingCode] ASC);


GO
CREATE TRIGGER [sub].[trg_tblApplicationSetting_Delete] ON [sub].[tblApplicationSetting]
AFTER DELETE
AS
BEGIN

	DECLARE @Creation_DateTime  datetime = GETDATE()
	DECLARE @TemplateID			int = 14
	DECLARE @EmailHeader		varchar(MAX),
			@EmailBody			varchar(MAX),
			@SubjectAddition	varchar(100) = '',
			@Recipients			varchar(MAX)

	DECLARE	@SettingCode	varchar(4),
			@SettingValue	varchar(100)

	IF @@SERVERNAME LIKE 'AITHQ%' OR DB_NAME() <> 'OTIBDS'
	BEGIN
		RETURN
	END

	SET @Recipients = 'support@ambitionit.nl'
	SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)

	SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', ISNULL(@Recipients, ''))
	SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))

	DECLARE crs_Deleted CURSOR 
	FOR	SELECT	SettingCode,
				SettingValue
		FROM	deleted
		WHERE	SettingName = 'IBANRejectionReason'

	OPEN crs_Deleted
	FETCH FROM	crs_Deleted INTO @SettingCode, @SettingValue

	WHILE @@FETCH_STATUS = 0 
	BEGIN 

		SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

		SET @EmailBody = REPLACE(@EmailBody, '<%SettingCode%>', ISNULL(@SettingCode, ''))
		SET @EmailBody = REPLACE(@EmailBody, '<%SettingValue%>', ISNULL(@SettingValue, ''))
		SET @EmailBody = REPLACE(@EmailBody, '<%Creation_DateTime%>', ISNULL(CONVERT(varchar(10), @Creation_DateTime, 105), ''))

		/* Send e-mail to OTIB finance.	*/
		--INSERT INTO eml.tblEmail
		--		   (EmailHeaders
		--		   ,EmailBody
		--		   ,CreationDate)
		--SELECT	'<headers>'
		--		+ '<header key="subject" value="OTIB-DS: Wijziging van de redenen van afkeur van IBAN-wijzigingen" />'
		--		+ '<header key="to" value="support@ambitionit.nl" />'
		--		+ '</headers>'	AS EmailHeaders,
		--		'Beste supportafdeling,<br>' +
		--		'<br>' +
		--		'Er zijn wijzigingen aangebracht aan de redenen van afkeur van IBAN-wijzigingen.<br>' + 
		--		'<br>' +
		--		'Bekijk deze wijzigingen s.v.p. en bekijk of OTIB hierover geïnformeerd moet worden. Als dat zo is, informeer Ronald Rijnsburger hier dan over op r.rijnsburger@otib.nl.<br>' +
		--		'<br>' +
		--		'<b>Verwijderde reden</b><br>' +
		--		'Code  = ' + @SettingCode + '<br>' +
		--		'Tekst = ' + @SettingValue + '<br>' +
		--		'<br><br>' + 
		--		'Deze e-mail is automatisch gegenereerd door trigger sub.trg_tblApplicationSetting_Delete op tabel sub.tblApplicationSetting om ' + CONVERT(varchar(5), GETDATE(), 108) + ' uur.'
		--				AS EmailBody,
		--		GETDATE()		AS CreationDate

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

		FETCH NEXT FROM	crs_Deleted INTO @SettingCode, @SettingValue
	END

	CLOSE crs_Deleted
	DEALLOCATE crs_Deleted 

END	
/*	-- sub.trg_tblApplicationSetting_Delete --------------------------------------------------	*/

GO
CREATE TRIGGER [sub].[trg_tblApplicationSetting_Insert] ON [sub].[tblApplicationSetting]
AFTER INSERT
AS
BEGIN
	DECLARE @Creation_DateTime  datetime = GETDATE()
	DECLARE @TemplateID			int = 15
	DECLARE @EmailHeader		varchar(MAX),
			@EmailBody			varchar(MAX),
			@SubjectAddition	varchar(100) = '',
			@Recipients			varchar(MAX)

	DECLARE	@SettingCode	varchar(4),
			@SettingValue	varchar(100)

	IF @@SERVERNAME LIKE 'AITHQ%' OR DB_NAME() <> 'OTIBDS'
	BEGIN
		RETURN
	END

	SET @Recipients = 'support@ambitionit.nl'
	SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)

	SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', ISNULL(@Recipients, ''))
	SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))

	DECLARE crs_Inserted CURSOR 
	FOR	SELECT	SettingCode,
				SettingValue
		FROM	inserted 
		WHERE	SettingName = 'IBANRejectionReason'

	OPEN crs_Inserted

	FETCH NEXT FROM	crs_Inserted INTO @SettingCode, @SettingValue

	WHILE @@FETCH_STATUS = 0 
	BEGIN 

		SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

		SET @EmailBody = REPLACE(@EmailBody, '<%SettingCode%>', ISNULL(@SettingCode, ''))
		SET @EmailBody = REPLACE(@EmailBody, '<%SettingValue%>', ISNULL(@SettingValue, ''))
		SET @EmailBody = REPLACE(@EmailBody, '<%Creation_DateTime%>', ISNULL(CONVERT(varchar(10), @Creation_DateTime, 105), ''))

		/* Send e-mail to OTIB finance.	*/
		--INSERT INTO eml.tblEmail
		--		   (EmailHeaders
		--		   ,EmailBody
		--		   ,CreationDate)
		--SELECT	'<headers>'
		--		+ '<header key="subject" value="OTIB-DS: Wijziging van de redenen van afkeur van IBAN-wijzigingen" />'
		--		+ '<header key="to" value="support@ambitionit.nl" />'
		--		+ '</headers>'	AS EmailHeaders,
		--		'Beste supportafdeling,<br>' +
		--		'<br>' +
		--		'Er zijn wijzigingen aangebracht aan de redenen van afkeur van IBAN-wijzigingen.<br>' + 
		--		'<br>' +
		--		'Bekijk deze wijzigingen s.v.p. en bekijk of OTIB hierover geïnformeerd moet worden. Als dat zo is, informeer Ronald Rijnsburger hier dan over op r.rijnsburger@otib.nl.<br>' +
		--		'<br>' +
		--		'<b>Nieuwe reden</b><br>' +
		--		'Code  = ' + @SettingCode + '<br>' +
		--		'Tekst = ' + @SettingValue + '<br>' +
		--		'<br><br>' + 
		--		'Deze e-mail is automatisch gegenereerd door trigger sub.trg_tblApplicationSetting_Insert op tabel sub.tblApplicationSetting om ' + CONVERT(varchar(5), GETDATE(), 108) + ' uur.'
		--				AS EmailBody,
		--		GETDATE()		AS CreationDate


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

		FETCH NEXT FROM	crs_Inserted INTO @SettingCode, @SettingValue
	END

	CLOSE crs_Inserted
	DEALLOCATE crs_Inserted 

END	
/*	-- sub.trg_tblApplicationSetting_Insert --------------------------------------------------	*/

GO
CREATE TRIGGER [sub].[trg_tblApplicationSetting_Update] ON [sub].[tblApplicationSetting]
AFTER UPDATE
AS
BEGIN

	DECLARE @Creation_DateTime  datetime = GETDATE()
	DECLARE @TemplateID			int = 16
	DECLARE @EmailHeader		varchar(MAX),
			@EmailBody			varchar(MAX),
			@SubjectAddition	varchar(100) = '',
			@Recipients			varchar(MAX)

	DECLARE	@NewSettingCode		varchar(4),
			@NewSettingValue	varchar(100),
			@OldSettingCode		varchar(4),
			@OldSettingValue	varchar(100)

	IF @@SERVERNAME LIKE 'AITHQ%' OR DB_NAME() <> 'OTIBDS'
	BEGIN
		RETURN
	END

	SET @Recipients = 'support@ambitionit.nl'
	SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)

	SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', ISNULL(@Recipients, ''))
	SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))

	DECLARE crs_Updated CURSOR 
	FOR	SELECT	i.SettingCode	AS NewSettingCode,
				i.SettingValue	AS NewSettingValue,
				d.SettingCode	AS OldSettingCode,
				d.SettingValue	AS OldSettingValue
		FROM	inserted i
		INNER JOIN deleted d 
		ON		d.ApplicationSettingID = i.ApplicationSettingID
		WHERE	i.SettingName = 'IBANRejectionReason'

	OPEN crs_Updated

	FETCH NEXT FROM	crs_Updated INTO @NewSettingCode, @NewSettingValue, @OldSettingCode, @OldSettingValue

	WHILE @@FETCH_STATUS = 0 
	BEGIN 

		SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

		SET @EmailBody = REPLACE(@EmailBody, '<%OldSettingCode%>', ISNULL(@OldSettingCode, ''))
		SET @EmailBody = REPLACE(@EmailBody, '<%OldSettingValue%>', ISNULL(@OldSettingValue, ''))
		SET @EmailBody = REPLACE(@EmailBody, '<%NewSettingCode%>', ISNULL(@NewSettingCode, ''))
		SET @EmailBody = REPLACE(@EmailBody, '<%NewSettingValue%>', ISNULL(@NewSettingValue, ''))
		SET @EmailBody = REPLACE(@EmailBody, '<%Creation_DateTime%>', ISNULL(CONVERT(varchar(10), @Creation_DateTime, 105), ''))

		/* Send e-mail to OTIB finance.	*/
		--INSERT INTO eml.tblEmail
		--		   (EmailHeaders
		--		   ,EmailBody
		--		   ,CreationDate)
		--SELECT	'<headers>'
		--		+ '<header key="subject" value="OTIB-DS: Wijziging van de redenen van afkeur van IBAN-wijzigingen" />'
		--		+ '<header key="to" value="support@ambitionit.nl" />'
		--		+ '</headers>'	AS EmailHeaders,
		--		'Beste supportafdeling,<br>' +
		--		'<br>' +
		--		'Er zijn wijzigingen aangebracht aan de redenen van afkeur van IBAN-wijzigingen.<br>' + 
		--		'<br>' +
		--		'Bekijk deze wijzigingen s.v.p. en bekijk of OTIB hierover geïnformeerd moet worden. Als dat zo is, informeer Ronald Rijnsburger hier dan over op r.rijnsburger@otib.nl.<br>' +
		--		'<br>' +
		--		'<b>Gewijzigde reden</b><br>' +
		--		'Code  = ' + @OldSettingCode + ' -> ' + @NewSettingCode + '<br>' +
		--		'Tekst = ' + @OldSettingValue + ' -> ' + @NewSettingValue + '<br>' +
		--		'<br><br>' + 
		--		'Deze e-mail is automatisch gegenereerd door trigger sub.trg_tblApplicationSetting_Update op tabel sub.tblApplicationSetting om ' + CONVERT(varchar(5), GETDATE(), 108) + ' uur.'
		--				AS EmailBody,
		--		GETDATE()		AS CreationDate

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

		FETCH NEXT FROM	crs_Updated INTO @NewSettingCode, @NewSettingValue, @OldSettingCode, @OldSettingValue
	END

	CLOSE crs_Updated
	DEALLOCATE crs_Updated 

END	
/*	-- sub.trg_tblApplicationSetting_Update --------------------------------------------------	*/
