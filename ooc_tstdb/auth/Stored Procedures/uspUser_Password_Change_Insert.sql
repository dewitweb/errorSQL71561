
CREATE PROCEDURE [auth].[uspUser_Password_Change_Insert]
@EmployerNumber     varchar(6),
@Email              varchar(50),
@PasswordResetToken varchar(50),
@TokenValidUntil    datetime
AS
/*	==========================================================================================
	Purpose: 	Update auth.tblUser_Password_Change on basis of PasswordChangeID.

    Notes:      This procedure is executed by the front-end.

	06-01-2020	Jaap van Assenbergh	OTIBSUB-1798	Banner per period or default
	04-12-2019	Sander van Houten	OTIBSUB-1565	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* Testdata.
DECLARE @PasswordChangeID   int = 0,
        @EmployerNumber     varchar(50) = 'svanhouten@ambitionit.nl',
        @Email              varchar(50) = 'svanhouten@ambitionit.nl',
        @PasswordResetToken varchar(50) = '8724393yuronlkfgnvh984',
        @TokenValidUntil    datetime = DATEADD(MI, 15, GETDATE())
-- */

DECLARE @TemplateID int = 2

DECLARE @EmailHeader		varchar(MAX),
		@EmailBody			varchar(MAX),
		@SubjectAddition	varchar(100) = ''

DECLARE @Creation_DateTime  datetime = GETDATE(),
		@Recipients			varchar(MAX),
        @UserID             int,
		@MailBanner		    varchar(100),
        @ValidityMinutes    varchar(18),
        @Return             int = 1

DECLARE @UrlPasswordResetToken varchar(MAX)

-- Get UserID through employernumber and e-mail address.
SELECT  @UserID = UserID
FROM    auth.tblUser
WHERE   Loginname = @EmployerNumber
AND     Email = @Email

IF @UserID IS NOT NULL
BEGIN
    -- Calculate the valid until datetime.
    IF @TokenValidUntil IS NULL
    BEGIN
        SELECT  @TokenValidUntil = DATEADD(MI, CAST(SettingValue AS int), @Creation_DateTime),
                @ValidityMinutes = SettingValue
        FROM    sub.tblApplicationSetting
        WHERE   SettingName = 'PasswordReset'
        AND     SettingCode = 'ValidMinutes'
    END
    ELSE
    BEGIN
        SELECT  @ValidityMinutes = SettingValue
        FROM    sub.tblApplicationSetting
        WHERE   SettingName = 'PasswordReset'
        AND     SettingCode = 'ValidMinutes'
    END
    
    -- Add new record
    INSERT INTO auth.tblUser_Password_Change
        (
            EmployerNumber,
            Email,
            PasswordResetToken,
            Creation_DateTime,
            ValidUntil,
            UserID
        )
    VALUES
        (
            @EmployerNumber,
            @Email,
            @PasswordResetToken,
            @Creation_DateTime,
            @TokenValidUntil,
            @UserID
        )

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

	SELECT @UrlPasswordResetToken = 
			CASE 
				WHEN DB_NAME() = 'OTIBDS' THEN CONCAT('https://otib-online.nl/wachtwoord-wijzigen/', @PasswordResetToken)
				WHEN DB_NAME() = 'OTIBDSTest' THEN CONCAT('http://ui.subsidiesysteem.local/wachtwoord-wijzigen/', @PasswordResetToken)
				WHEN DB_NAME() = 'OTIBDS_Acceptatie' THEN CONCAT('https://acceptatie.otib-online.nl/wachtwoord-wijzigen/', @PasswordResetToken)
			END

	SET @EmailBody = REPLACE(@EmailBody, '<%PasswordResetToken%>', ISNULL(@UrlPasswordResetToken, '') )
	SET @EmailBody = REPLACE(@EmailBody, '<%ValidityMinutes%>', @ValidityMinutes)
	SET @EmailBody = REPLACE(@EmailBody, '<%MailBanner%>', ISNULL(@MailBanner, ''))

	---- Insert e-mail for sending.
	--INSERT INTO eml.tblEmail
	--	(
 --           EmailHeaders,
	--		EmailBody,
	--		CreationDate
 --       )
	--VALUES
 --       (
 --           '<headers>'
 --               + '<header key="subject" value="OTIB Online: Wachtwoord vergeten" />'
 --               + '<header key="to" value="' + REPLACE(@Email, '&', '&amp;') + '" />'
 --               + '</headers>',
	--		'<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>'
 --               + 'Geachte mevrouw, heer,<br>'
 --               + '<br>'
 --               + 'U kunt uw wachtwoord wijzigen door op onderstaande link te klikken:<br>'
 --               + CASE 
	--				WHEN DB_NAME() = 'OTIBDS' THEN CONCAT('https://otib-online.nl/wachtwoord-wijzigen/', @PasswordResetToken)
	--				WHEN DB_NAME() = 'OTIBDSTest' THEN CONCAT('http://ui.subsidiesysteem.local/wachtwoord-wijzigen/', @PasswordResetToken)
	--				WHEN DB_NAME() = 'OTIBDS_Acceptatie' THEN CONCAT('https://acceptatie.otib-online.nl/wachtwoord-wijzigen/', @PasswordResetToken)
	--			  END + '<br>'
 --               + 'Deze link is maximaal ' + @ValidityMinutes + ' minuten geldig en slechts eenmaal te gebruiken.<br>'
 --               + '<br>' + 'Als u nog vragen heeft, kunt u contact opnemen met de OTIB Supportdesk op telefoonnummer 0800-885 58 85.<br>' +
 --               + '<br>' + 'Met vriendelijke groet,<br>' +
 --               + 'OTIB<br>'
 --               + '<a href="mailto:support@otib.nl">support@otib.nl</a><br>'
 --               + 'T 0800 885 58 85<br>'
 --               + '<img src="' + @MailBanner + '" width="450" style="border: none;" />'
 --               + '</p>',
	--		@Creation_DateTime
 --       )

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

    SET @Return = 0
END

EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

RETURN @Return

/*	== auth.uspUser_Password_Change_Insert ===================================================	*/
