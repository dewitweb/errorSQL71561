
CREATE PROCEDURE [auth].[uspUser_Password_Change_Update]
@UserID         int,
@Password_New   varchar(100)
AS
/*	==========================================================================================
	Purpose: 	Update auth.tblUser_Password_Change on basis of UserID.

    Notes:      This procedure is executed by the front-end.
                The password (old and new) are saved encrypted.

	06-01-2020	Jaap van Assenbergh	OTIBSUB-1798	Banner per period or default
	04-12-2019	Sander van Houten	OTIBSUB-1565	Initial version.
	==========================================================================================	*/

DECLARE @ExecutedProcedureID int = 0
EXEC @ExecutedProcedureID = ait.uspExecutedProcedure @ExecutedProcedureID, @@PROCID

/* Testdata.
DECLARE @UserID         int = 46185,
        @Password_New   varchar(100) = 'TF4nFFa2@6'
-- */

DECLARE @Creation_DateTime  datetime = GETDATE()

DECLARE @TemplateID			int
DECLARE @EmailHeader		varchar(MAX),
		@EmailBody			varchar(MAX),
		@SubjectAddition	varchar(100) = ''

DECLARE @Return             int = 2,
		@Recipients			varchar(MAX),
 		@MailBanner	        varchar(100),
        @Email              varchar(50),
        @PasswordChangeID   int = 0,
        @EmployerNumber	    varchar(6),
        @ClickedOnLink      bit,
        @GetDate            datetime = GETDATE()

/* Get EmployerNumber and Email.  */
SELECT  @EmployerNumber = LEFT(Loginname, 6),
        @Email = email
FROM    auth.tblUser
WHERE   UserID = @UserID

-- Open the symmetric key with which to encrypt the data.  
OPEN SYMMETRIC KEY SSN_Key_01  
DECRYPTION BY CERTIFICATE EncryptedSetting001;  

-- Check if this is a change for a forgotten password of a regular change by the user.
SELECT  @PasswordChangeID = PasswordChangeID
FROM    auth.tblUser_Password_Change
WHERE	UserID = @UserID
AND     Password_New IS NULL 
AND     ValidUntil >= @GetDate

SET @PasswordChangeID = ISNULL(@PasswordChangeID, 0)

IF @PasswordChangeID <> 0
BEGIN   -- Update existing record.
    UPDATE	upc
    SET		upc.Password_New = EncryptByKey(Key_GUID('SSN_Key_01'), @Password_New),
            @Email = upc.Email,
            @PasswordChangeID = @PasswordChangeID
    FROM    auth.tblUser_Password_Change upc
    WHERE	upc.UserID = @UserID
    AND     upc.Password_New IS NULL
    AND     upc.ValidUntil >= @GetDate

    SET @ClickedOnLink = 1
END
ELSE
BEGIN   -- Insert new record
    INSERT INTO auth.tblUser_Password_Change
        (
            EmployerNumber,
            Email,
            PasswordResetToken,
            Creation_DateTime,
            ValidUntil,
            UserID,
            Password_New
        )
    VALUES
        (
            @EmployerNumber,
            @Email,
            '',
            @GetDate,
            @GetDate,
            @UserID,
            EncryptByKey(Key_GUID('SSN_Key_01'), @Password_New)
        )

    SET @PasswordChangeID = SCOPE_IDENTITY()

    SET @ClickedOnLink = 0
END

-- Send change to Horus.
IF EXISTS(SELECT 1 FROM sys.servers WHERE NAME = N'HORUS_P')
BEGIN
    DECLARE @SQL			varchar(MAX),
            @Result			varchar(8000),
		    @FinalResult	varchar(50),
            @Seconds        tinyint = 1

    DECLARE @tblResult TABLE (Result xml)

    SET	@SQL = 'BEGIN ? :=OLCOWNER.HRS_PCK_OTIBDS.WGR_WIJZIG_WACHTWOORD('
                + '''' + @EmployerNumber + ''', '
                + '''' + @Password_New + ''''
                + '); END;'

    -- Try until a reply is received from Horus with a maximum of 5 seconds. 
    WHILE (@Return = 2 AND @Seconds <= 5)
    BEGIN
        WAITFOR DELAY '00:00:01'

        SET @GetDate = GETDATE()
        
        IF DB_NAME() = 'OTIBDS'
            EXEC(@SQL, @Result OUTPUT) AT HORUS_P
        ELSE
            EXEC(@SQL, @Result OUTPUT) AT HORUS_A

        -- Save result.
        INSERT INTO @tblResult (Result) VALUES (@Result)

        SELECT	@FinalResult = x.r.value('resultaat[1]', 'varchar(4)')
        FROM @tblResult
        CROSS APPLY Result.nodes('hrs_pck_otibds.wgr_wijzig_wachtwoord') AS x(r)

        PRINT @FinalResult

        IF @FinalResult = 'Goed'
        BEGIN
            SET @Return = 0
        END

        IF @FinalResult = 'Fout'
        BEGIN
            SET @Return = 1
        END

        SET  @Seconds = @Seconds + 1
    END
END
ELSE
BEGIN
    SELECT  @GetDate = GETDATE(),
            @FinalResult = 'Goed',
            @Return = 0
END

/*  Update tblUser_Password_Change. */
UPDATE	auth.tblUser_Password_Change
SET		SendToHorus = @GetDate,
        ResultFromHorus = @FinalResult,
        ChangeSuccessful = CASE @Return
                            WHEN 0 THEN 1
                            ELSE 0
                           END
WHERE	PasswordChangeID = @PasswordChangeID

/*  Send a result e-mail.   */
-- Get MailBanner location.
SELECT	@MailBanner = COALESCE(apse.SettingValue, aps.SettingValue)
FROM	sub.tblApplicationSetting aps
LEFT JOIN sub.tblApplicationSetting_Extended apse 
	ON	apse.ApplicationSettingID = aps.ApplicationSettingID 
	AND	GETDATE() BETWEEN apse.StartDate AND apse.EndDate
WHERE	aps.SettingName = 'BaseURL'
AND		aps.SettingCode = 'AssetsMailBanner'

IF @Return = 0 
BEGIN
	SET @Recipients = REPLACE(@Email, '&' , '&amp;')
	SET @SubjectAddition = ''

	IF @ClickedOnLink = 0 
		SET @TemplateID = 3
	ELSE
		SET @TemplateID = 4
END
ELSE
BEGIN
	SET @Recipients = 'support@ambitionit.nl' + CASE WHEN DB_NAME() = 'OTIBDS' THEN ';jan.odijk@odijk-it.nl' ELSE '' END
	SET @SubjectAddition = ' (' + CASE WHEN DB_NAME() = 'OTIBDS' THEN 'PRD' ELSE 'ACC' END + ')'
	SET @TemplateID = 5
END

SET @EmailHeader = eml.usfGetEmail_Header (@TemplateID)
SET @EmailBody = eml.usfGetEmail_Body (@TemplateID)

SET @EmailHeader = REPLACE(@EmailHeader, '<%Recipients%>', ISNULL(@Recipients, ''))
SET @EmailHeader = REPLACE(@EmailHeader, '<%SubjectAddition%>', ISNULL(@SubjectAddition, ''))
SET @EmailBody = REPLACE(@EmailBody, '<%Email%>', ISNULL(@Email, ''))
SET @EmailBody = REPLACE(@EmailBody, '<%MailBanner%>', ISNULL(@MailBanner, ''))

-- Insert e-mail for sending.
--IF @Return = 0
--BEGIN   -- OK. Send e-mail to employer.

--    INSERT INTO eml.tblEmail
--        (
--            EmailHeaders,
--            EmailBody,
--            CreationDate
--        )
--    VALUES
--        (
--            '<headers>'
--                + CASE @ClickedOnLink
--                    WHEN 0 THEN '<header key="subject" value="OTIB Online: Wachtwoord gewijzigd" />'
--                    ELSE '<header key="subject" value="OTIB Online: Wachtwoord vergeten" />'
--                  END
--                + '<header key="to" value="' + REPLACE(@Email, '&', '&amp;') + '" />'
--                + '</headers>',
--            '<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>'
--                + 'Geachte mevrouw, heer,<br>'
--                + '<br>'
--                + CASE @ClickedOnLink
--                    WHEN 0 THEN 'Uw wachtwoord is succesvol gewijzigd. U kunt nu inloggen met het nieuwe wachtwoord.<br>'
--                              + 'Als u nog vragen heeft, kunt u contact opnemen met de OTIB Supportdesk op telefoonnummer 0800-885 58 85.<br>'
--                    ELSE 'Uw wachtwoord is gewijzigd. U kunt hiermee inloggen op <a href="https://www.otib-online.nl">https://www.otib-online.nl</a>.<br>'
--                       + 'Is het wachtwoord niet door u gewijzigd? Neem dan contact op met de OTIB Supportdesk op telefoonnummer 0800-885 58 85.<br>'
--                  END
--                + '<br>' 
--                + '<br>' 
--                + 'Met vriendelijke groet,<br>'
--                + 'OTIB<br>'
--                + '<a href="mailto:support@otib.nl">support@otib.nl</a><br>'
--                + 'T 0800 885 58 85<br>'
--                + '<img src="' + @MailBanner + '" width="450" style="border: none;" />'
--                + '</p>',
--            GETDATE()
--        )
--END
--ELSE
--BEGIN   -- NOT OK. Send e-mail to Ambition IT / Odijk-IT.
--    INSERT INTO eml.tblEmail
--        (
--            EmailHeaders,
--            EmailBody,
--            CreationDate
--        )
--    VALUES
--        (
--            '<headers>'
--                + '<header key="subject" value="OTIB Online: Wachtwoord vergeten (' + CASE WHEN DB_NAME() = 'OTIBDS' THEN 'PRD' ELSE 'ACC' END + ')" />'
--                + '<header key="to" value="support@ambitionit.nl' + CASE WHEN DB_NAME() = 'OTIBDS' THEN ';jan.odijk@odijk-it.nl' ELSE '' END + '" />'
--                + '</headers>',
--            '<style type="text/css">p {font-family: arial;font-size: 14.5px}</style><p>'
--                + 'Beste supportdesk,<br>'
--                + '<br>'
--                + 'De onderstaande wachtwoord wijziging is niet gelukt: ' + @Email
--                + '</p>',
--            GETDATE()
--        )
--END

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

RETURN @Return

/*	== auth.uspUser_Password_Change_Update ===================================================	*/
